macro _invoke proc,[arg]
 { common
    if ~ arg eq
   reverse
     pushd arg
   common
    end if
   call dword [proc] }


macro _invoke_cdecl proc,[arg]
 {
   common
    .args_c=0
    if ~ arg eq
   reverse
     pushd arg
     .args_c = .args_c+1
   common
    end if
   call dword [proc]
   if .args_c > 0
   add esp, .args_c*4
   end if }

macro _call_cdecl proc,[arg]
 {
   common
    .args_c=0
    if ~ arg eq
   reverse
     pushd arg
     .args_c = .args_c+1
   common
    end if
   call proc
   if .args_c > 0
   add esp, .args_c*4
   end if }


; === Patching macros ===

p_savedorg = 0
p_sectionset = 0

macro pushorg value*
{
  p_wasorg = $
  org value
  p_inorg = $
  p_savedorg = 1
}

macro poporg
{
  local orgsize
  orgsize = $ - p_inorg
  org p_wasorg + orgsize
  p_savedorg = 0
}

macro patchsection value*
{
  p_sectionset = 1
  p_sectionorg = value
}

macro patchfile name*
{
  virtual
    @@:
    file name
    p_filesize = $ - @b
  end virtual
  p_start = $
  p_pointer = 0
  p_filename equ name
}

macro patchat address*
{
  if p_savedorg = 1
    poporg
  end if

  p_pointer = p_pointer - p_start + $
  p_toadd = address - $

  if address >= 0
    if p_toadd >= 0
      if p_pointer + p_toadd <= p_filesize
        file p_filename: p_pointer, p_toadd
      else
        p_addpart = 0
        if p_pointer < p_filesize
          p_addpart = p_filesize - p_pointer
          file p_filename: p_pointer, p_addpart
        end if
        rb p_toadd - p_addpart
      end if
    else
      "Error: can't move backwards."
    end if
  else
    "Error: invalid address, must be >= 0."
  end if

  p_start = $
  p_pointer = p_pointer + p_toadd

  if p_sectionset = 1
    pushorg p_sectionorg + address
  end if

}

; завершает кусок патча функции - добивает неиспользованное
; место nop'ами, ругается, если код превысил разумные пределы
macro patchtill endAddress*
{
    pt_curAddress = $
    ; вычисление адреса
    if p_sectionset = 1
        pt_curAddress = pt_curAddress - p_sectionorg
    end if
    
    ; проверка и вывод человекочитаемой ошибки
    if pt_curAddress > endAddress
        _print_int "***ERROR*** Patch overflow error, expecting end of patch at", endAddress
        _print_int "***ERROR*** but current offset is", pt_curAddress
        error ABORTING COMPILATION
    end if
    
    ; добивка nop'ами
    if pt_curAddress < endAddress
        db (endAddress - pt_curAddress) dup (090h)
    end if
    
}

macro patchend
{
  if p_savedorg
    poporg
  end if

  p_pointer = p_pointer - p_start + $
  p_toadd = p_filesize - $

  if p_toadd >= 0
    if p_pointer + p_toadd <= p_filesize
      file p_filename: p_pointer, p_toadd
    else
      p_addpart = 0
      if p_pointer < p_filesize
        p_addpart = p_filesize - p_pointer
        file p_filename: p_pointer, p_addpart
      end if
      db p_toadd - p_addpart dup 0
    end if
  end if
}


macro _print_int header*, integer*, usebits
{
    if usebits + 1 = 1
        bits = 32
    else
        bits = usebits
    end if
    display header
    display " "
    repeat bits/4
        d = '0' + integer shr (bits-%*4) and 0Fh
        if d > '9'
            d = d + 'A'-'9'-1
        end if
        display d
    end repeat
    display 13,10
}

macro _assertEqual got*, expected* { 
    if got <> expected
        _print_int "Got", got
        _print_int "Expected", expected
        error "not equal values"
    end if
}

; vim:ft=fasm

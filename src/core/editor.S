@ Copyright [2018] Anthony Tonizzo (atonizzo@gmail.com)
@
@   Licensed under the Apache License, Version 2.0 (the "License");
@   you may not use this file except in compliance with the License.
@   You may obtain a copy of the License at
@
@       http://www.apache.org/licenses/LICENSE-2.0
@
@   Unless required by applicable law or agreed to in writing, software
@   distributed under the License is distributed on an "AS IS" BASIS,
@   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@   See the License for the specific language governing permissions and
@   limitations under the License.

@ These two constants determine the upper left corner (aka the origin) of the
@  editable area of a screen.
                CONSTANT    editor_link_address, 0, dx, cdx, 3

                CONSTANT    editor_link_address, 0, dy, cdy, 4

@ These two variables are used for cursor movement. They are added to the
@  previous two constants to determine the position of the cursor inside the
@  editable area.
                VARIABLE    editor_link_address, 0, row, row, row_var
                VARIABLE    editor_link_address, 0, col, col, col_var
                VARIABLE    editor_link_address, 0, tabconst, tabconst, tabconst_var

@ i/r ( -- )
@ This variable holds the state of the editor, insert vs. replace.
                VARIABLE    editor_link_address, 0, i/r, islashr, islashr_var

@ scr ( -- )
@ This variable holds the number of the block most recently displayed.
                VARIABLE    editor_link_address, 0, scr, scr, scr_var

@ clear-line ( -- )             \ Move cursor back one space.
@ : clear-line
@     ." \x1b[K" ;
                COLON       editor_link_address, 0, clear-line, clearline
                .word       dotqp
                .byte       1f - . - 1
                .ascii      "\x1b[K"
1:              .align      2, 0
                .word       exit

@: bbelow ( -- n )
@: bbelow
@    16 row @ - c/l * b/buf + ;
                COLON       editor_link_address, 0, bbelow, bbelow
                .word       dolit, 16, row, at, minus
                .word       cslashl, star
                .word       bslashbuf, plus
                .word       exit

@ @cursor ( -- r c )        \ Get cursor position.
@ : @cursor
@     row @ col @ ;
                make_link   editor_link_address
                .byte       7
                .ascii      "@cursor"
                .align      2, 0
                .equ        atcursor, . + 1
                ENTER
                .word       row, at, col, at, exit

@ !cursor ( r c -- )        \ Set cursor position to (r,c) but does not move
@                           \  the cursor.
@ : !cursor
@     col ! row ! ;
                COLON       editor_link_address, 0, !cursor, stocurs
                .word       col, store, row, store
                .word       exit

@: showcoord  ( -- )      \ show insert on/off
@
@: showcoord
@    19 28 at-xy
@    ."         "         \ Clear old characters.
@    19 28 at-xy
@    '(' emit             \ Write new coordinates.
@    row @
@    <# # #> type
@    col @
@    <# # #> type
@    ')' emit
@    cdx ROWS_PER_BUFFER +
@    11 atxy              \ Position the cursor to type the "modified" asterisk.
@    prev @ @             \ UPDATE bit set?
@    ATTR_BUFFER_UPDATE and
@    if
@      txt-fg-red
@      '*' emit
@      txt-normal
@    else
@      space
@    then ;
                COLON       editor_link_address, 0, showcoord, showcoord
                .word       cdx, dolit, ROWS_PER_BUFFER, plus
                .word       dolit, 28, atxy
                .word       dotqp
                .byte       showcoord_strend1 - . - 1
                .ascii      "        "
showcoord_strend1:
                .align      2, 0
                .word       cdx, dolit, ROWS_PER_BUFFER, plus
                .word       dolit, 28, atxy
                .word       dotqp
                .byte       showcoord_strend2 - . - 1
                .ascii      "\x1b[34m("
showcoord_strend2:
                .align      2, 0
                .word       row, at @, oneplus
                .word       bdigs, digs, edigs
                .word       types
                .word       dolit, ',', emit
                .word       col, at @, onepplus
                .word       bdigs, digs, edigs
                .word       types
                .word       dotqp
                .byte       1f - . - 1
                .ascii      ")\x1b[0m"
1:              .align      2, 0
                .word       cdx, dolit, ROWS_PER_BUFFER, plus
                .word       dolit, 11, atxy
                .word       prev, at, at
                .word       dolit, ATTR_BUFFER_UPDATE, andd
                .word       qbranch, 2f
                .word       txtfgred
                .word       dolit, '*', emit
                .word       txtnormal
                .word       branch, 3f
2:              .word       space
3:              .word       exit

@ <cxy> ( -- )
@ : <cxy>
@     col @ dx +  \ Add the screen offset to the cursor coordinates.
@     row @ dy +
@     at-xy  ;    \ Move the cursor to the final destination.
                COLON       editor_link_address, 0, <cxy>, xcxy
                .word       showcoord
                .word       row, at, cdx, plus
                .word       col, at, cdy, plus
                .word       atxy
                .word       exit

@ <hom> ( -- )
@: <hom>                 \ Moves the cursor to the start of the block area.
@    0 0 !cursor
@    <cxy> ;
                COLON       editor_link_address, 0, <hom>, xhom
                .word       dolit, 0, dupp, stocurs
                .word       xcxy
                .word       exit

@ lstart ( -- adr )
@ : lstart               \ Returns the address of the start of the line with
@                        \  cursor within the buffer being edited.
@     prev @             \ Buffer being edited.
@     fourplus           \ First byte.
@     row @ c/l *        \ Row offset.
@     + ;                \ Add to the start of start of the buffer.
                COLON       editor_link_address, 0, lstart, lstart
                .word       prev, at, fourplus
                .word       row, at
                .word       cslashl, star
                .word       plus
                .word       exit

@ lend ( -- adr )        \ Returns the address of the end of the line with
@                        \  the cursor within the buffer being edited.
@ : lend
@     c/l 1- lstart + ;
                COLON       editor_link_address, 0, lend, lend
                .word       cslashl, oneminus
                .word       lstart, plus
                .word       exit

@ <sol>  ( -- )          \ Moves the cursor to the start of the line it is in.
@ : <sol>
@     0 col !
@     <cxy> ;
                COLON       editor_link_address, 0, <sol>, xsol
                .word       dolit, 0, col, store, xcxy
                .word       exit

@ showstatus ( -- )
@ : showstatus
@     dx 2- dy at-xy
@     ." scr # "
@     scr @ .
@     16 0 at-xy
@     <cxy> ;
                COLON       editor_link_address, 0, showstatus, showstatus
                .word       cdx, dolit, ROWS_PER_BUFFER, plus
                .word       cdy, atxy
                .word       dotqp
                .byte       1f - . - 1
                .ascii      "\x1b[34mscr # "
1:              .align      2, 0
                .word       scr, at, dot
                .word       dotqp
                .byte       2f - . - 1
                .ascii      "\x1b[0m"
2:              .align      2, 0
                .word       dolit, 16, dolit, 0
                .word       atxy
                .word       xcxy
                .word       exit

@: showmode  ( -- )      \ show insert on/off
@
@: showmode
@    65 0 at-xy
@    i/r @
@    if
@      ." insert"
@    else
@      6 spaces
@    then ;
                COLON       editor_link_address, 0, showmode, showmode
                .word       cdx, dolit, ROWS_PER_BUFFER, plus
                .word       dolit, 20, atxy
                .word       islashr, at
                .word       qbranch, 1f
                .word       dotqp
                .byte       insert_strend1 - . - 1
                .ascii      "\x1b[34mINS\x1b[0m"
insert_strend1: .align      2, 0
                .word       branch, 2f
1:              .word       dotqp
                .byte       insert_strend2 - . - 1
                .ascii      "\x1b[34mOVR\x1b[0m"
insert_strend2: .align      2, 0
2:              .word       exit

@ border ( -- )
@
@ : border
@    padchar @ >r          \ Save the pad char.
@    ' ' padchar !         \ Use a blank space for padding.
@    dx dy 1- at-xy
@    c/l @ 1- 0
@    do
@      i tabconst 2* mod
@      if
@        '-'
@      else
@        '!'
@      then
@      emit
@    loop
@    '!' emit
@    dx 0 at-xy
@    16 0
@    do
@      i 2 u.r cr
@    loop
@    cr ."   buff"
@    r> padchar ! ;        \ Restore the pad char.
                COLON       editor_link_address, 0, border, border
                .word       padchar, at, tor
                .word       dolit, ' ', padchar, store
                .word       cdx, oneminus, cdy, oneminus, atxy
                .word       cslashl, oneminus, dolit, 0
                .word       xdo
3:              .word       index, tabconst, at, twostar
                .word       slmod
                .word       drop
                .word       qbranch, 1f
                .word       dolit, '-'
                .word       branch, 2f
1:              .word       dolit, '!'
2:              .word       emit
                .word       xloop, 3b
                .word       dolit, '!', emit
                .word       cdx, dolit, 0, atxy
                .word       dolit, 16, dolit, 0
                .word       xdo
4:              .word       index
                .word       dolit, 2, udotr, cr
                .word       xloop, 4b
                .word       rfrom, padchar, store
                .word       exit

@ cpos ( -- adr )       \ Returns the memory address of the position where
@                       \  the cursor is within the buffer being edited.
@ : cpos
@     prev @            \ Address of buffer where the cursor is.
@     4+                \ Address of first byte of buffer.
@     row @ c/l * +     \ Reach beginning of row with cursor.
@     col @ + ;         \ Add column.
                COLON       editor_link_address, 0, cpos, cpos
                .word       prev, at, fourplus
                .word       row, at, cslashl, star, plus
                .word       col, at, plus
                .word       exit

@ cup ( -- )                \ Move cursor up one line.
@ : cup
@     row @ 0 >             \ Make sure we are not going out of the screen.
@     if
@       -1 row +!
@     then ;
                COLON       editor_link_address, 0, cup, cup
                .word       row, at, dolit, 0, grthan
                .word       qbranch, 1f
                .word       dolit, -1, row, pstor
                .word       xcxy
1:              .word       exit

@ cdown  ( -- )
@ : cdown
@     row @ 15 <
@     if
@       1 row +!
@       <dlf>
@     then ;
                COLON       editor_link_address, 0, cdown, cdown
                .word       row, at, dolit, 15, lthan
                .word       qbranch, 1f
                .word       dolit, 1, row, pstor
                .word       xcxy
1:              .word       exit


@ cleft  ( -- )
@ : cleft
@     col @ 0 >
@     if
@       -1 col +!
@       <bsp>
@     then ;
                COLON       editor_link_address, 0, cleft, cleft
                .word       col, at, dolit, 0, grthan
                .word       qbranch, 1f
                .word       dolit, -1, col, pstor
@                .word       xbsp
                .word       xcxy
1:              .word       exit

@ mode ( -- )          \ Toggle mode.
@ : mode
@     i/r @
@     not i/r !
@     showmode  <cxy> ;
                COLON       editor_link_address, 0, mode, mode
                .word       islashr, at, onecomp
                .word       islashr, store
                .word       showmode
                .word       xcxy
                .word       exit

@ bleft ( -- n )        \ Compute the number of bytes between the cursor and
@                       \  the end of the line.
@ : bleft
@     lend              \ Calculate the address of the end of the line.
@     cpos - ;          \ Subtract the current position.
                COLON       editor_link_address, 0, bleft, bleft
                .word       lend, cpos, minus
                .word       exit

@ loadblk ( -- )
@ Loads a block from Flash into a buffer, obtaining one in the process, and
@  then copies the contents of the block from Flash to RAM.
@
@ : loadblk
@     scr @
@     block
@     drop
@     prev @                \ Destination address in RAM.
@     4+ dup
@     c/b + swap
@     do
@         I c@
@         BL '~' 1+ within  \ Remove un printable characters.
@         0=
@         if
@             BL I c!       \ Invalic charatcer ar ereplaced with blanks.
@         then
@     loop ;
                COLON       editor_link_address, 0, loadblk, loadblk
                .word       scr, at
                .word       block, drop
                .word       prev, at, fourplus, dupp
                .word       bslashbuf, plus, swap
                .word       xdo
1:              .word       index, cat
                .word       dolit, ' ', dolit, '~' + 1, within
                .word       zequ
                .word       qbranch, 2f
                .word       blank, index, cstore
2:              .word       xloop, 1b
                .word       exit

@ delete  ( -- )
@ : delete
@     col @ c/l <
@     if
@       cpos 1+ cpos bleft cmove
@       ' ' lend c!
@       typeline
@       <cxy>
@     then ;
                COLON       editor_link_address, 0, delete, delete
                .word       col, at, cslashl, lthan
                .word       qbranch, 1f
                .word       cpos, oneplus, cpos, bleft, cmove
                .word       blank, lend, cstore
                .word       typeline
                .word       xcxy
1:              .word       exit

@ overtype ( char -- )
@ : overtype
@     col @ c/l <      \ make sure there is room for a new character.
@     if
@       dup
@       emit           \ Send the character to the terminal
@       cpos c!        \ Store it in memory.
@       1 col +!       \ Increment column count.
@     else
@       drop
@       beep
@     then ;
                COLON       editor_link_address, 0, overtype, overtype
                .word       col, at, cslashl, lthan
                .word       qbranch, overtype1
                .word       dupp, emit, cpos, cstore
                .word       dolit, 1, col, pstor
                .word       exit
overtype1:      .word       drop, beep
                .word       exit

@ openup  ( -- )
@ : openup
@     col @ c/l <         \ Make sure we are not at the end of the line.
@     lend c@ bl =        \ Make sure there is room left for an additional
@                         \  character at the end of the line.
@     and
@     if
@       cpos              \ Source address for the transfer
@       dup 1+            \ Destination address for the transfer.
@       bleft             \ Bytes to move.
@       cmove>            \ Move the bytes over one character.
@       bl cpos c!        \ Store a blank in the newly created space.
@     else
@       beep
@     then ;
                COLON       editor_link_address, 0, openup, openup
                .word       col, at, cslashl, lthan
                .word       lend, cat, blank, equal, andd
                .word       qbranch, 1f
                .word       cpos, dupp, oneplus
                .word       bleft, cmovet
                .word       blank, cpos, cstore
                .word       exit
1:              .word       beep
                .word       exit

@ clrmsg  ( -- )        \ clear command line
@ : clrmsg
@     1 22 at-xy
@     clear-line ;
                COLON       editor_link_address, 0, clrmsg, clrmsg
                .word       dolit, 1, dolit, 22, atxy
                .word       clearline
                .word       exit

@ ?exit ( -- )         \ exit editor
@ : ?exit
@     clrmsg
@     ."exit: (s)ave, (q)uit ? "
@     key
@     dup emit
@     dup 's' =
@     if
@       drop
@       update
@       flush
@       1+          \ Add one to the flag on the stack so we exit 'editloop'.
@     else
@       'q' =
@       if
@         empty-buffers \ Quit without saving the buffer to storage.
@         1+        \ Add one to the flag on the stack so we exit 'editloop'.
@       then
@     then
@     clrmsg
@     <cxy> ;
                COLON       editor_link_address, 0, qexit, qexit
                .word       clrmsg
                .word       dotqp
                .byte       qexit_strend - . - 1
                .ascii      "exit: (s)ave, (q)uit ? "
qexit_strend:   .align      2, 0
                .word       key, dupp, emit
                .word       dupp, dolit, 's', equal
                .word       over, dolit, 'S', equal, orrr
                .word       qbranch, 1f
                .word       drop
@                .word       update, flush
                .word       oneplus
                .word       branch, 2f
1:              .word       dupp, dolit, 'q', equal
                .word       swap, dolit, 'Q', equal, orrr
                .word       qbranch, 2f
                .word       emptybuffers
                .word       oneplus
2:              .word       clrmsg
                .word       exit

@ insert  ( char -- )
@: insert
@  lend c@         \ Get the last character of the line
@  bl =            \ Is it blank?
@  if
@    openup        \ Move the characters over one space and write a blank.
@    overtype      \ Print the new character and increment the column count.
@    typeline      \ Print the rest of the line to the terminal.
@    <cxy>
@  else
@    drop
@    beep
@  then ;
                COLON       editor_link_address, 0, insert, insert
                .word       lend, cat
                .word       blank, equal
                .word       qbranch, 1f
                .word       openup
                .word       overtype
                .word       typeline
                .word       xcxy
                .word       exit
1:              .word       drop, beep
                .word       exit

@ cright ( -- )
@ : cright
@   col @ c/l 1- <
@   if
@     1 col +!
@     xcxy
@   then ;
                COLON       editor_link_address, 0, cright, cright
                .word       col, at, cslashl, oneminus, lthan
                .word       qbranch, 1f
                .word       dolit, 1, col, pstor
                .word       xcxy
1:              .word       exit

@ htab ( -- )          \ move cursor to next tab stop
@ : htab  ( -- )
@  col @ 0             \ Dividend is a double.
@  tabconst            \ Divisor.
@  um/mod              \ Number of spaces from the previous TAB boundary.
@  tabconst swap -     \ Number of spaces to the next TAB boundary.
@  0
@  do
@    right
@  loop
@  <cxy> ;
                COLON       editor_link_address, 0, htab, htab
                .word       col, at, dolit, 0, tabconst, at
                .word       ummod, drop
                .word       tabconst, at
                .word       swap, minus
                .word       dolit, 0
                .word       xdo
1:              .word       cright
                .word       xloop, 1b
                .word       xcxy
                .word       exit

@ typeline  ( -- ) \ display current line
@ : typeline
@     cpos         \ Address (within the buffer being edited) of the character
@                  \  under the cursor.
@     bleft 1+
@     -trailing
@     type
@     clear-line ;
                COLON       editor_link_address, 0, typeline, typeline
                .word       cpos
                .word       bleft, oneplus
                .word       mtrailing, types
                .word       clearline
                .word       exit

@ showlines ( -- )     \ Print the contents of the buffer to the terminal.
@ : showlines
@     @cursor          \ Save current cursor position on the stack.
@     rslashb row @    \ Type lines from the one the cursor is in to the end
@     do               \  of the buffer.
@       i row !
@       <sol>          \ Move cursor to the start of the line.
@       typeline
@     loop
@     <cxy>
@     !cursor          \ Restore cursor position on the stack.
@     <cxy> ;
                COLON       editor_link_address, 0, showlines, showlines
                .word       atcursor
                .word       rslashb, row, at
                .word       xdo
1:              .word       index, row, store
                .word       xsol
                .word       typeline
                .word       xloop, 1b
                .word       xcxy
                .word       stocurs, xcxy
                .word       exit

@ showblk  ( -- )          \ Display the content of the block.
@: showblk
@    @cursor <hom>
@    showstatus
@    showlines
@    !cursor <cxy> ;
                COLON       editor_link_address, 0, showblk, showblk
                .word       cui
                .word       atcursor, xhom
                .word       showstatus
                .word       showlines
                .word       stocurs, xcxy
                .word       cuv
                .word       exit

@ restore ( -- )
@: restore
@    loadblk
@    showblk ;
                COLON       editor_link_address, 0, restore, restore
                .word       loadblk
                .word       showblk
                .word       exit

@ empty-buffers ( -- )
@ Unassign all block buffers. Do not transfer the contents of any UPDATEd block
@  buffer to mass storage.
@
@: empty-buffers
@    limit first
@    do
@      i
@      ~ATTR_BUFFER_UPDATE
@      over !               \ Assign block number that will not match any
@                           \  real block.
@      4+                   \ Reach start of buffer area.
@      bslashbuf ' ' fill   \ Fill the buffer area with blanks.
@      bslashbuf 4+         \ Increment for +loop.
@    +loop ;
                COLON       editor_link_address, 0, empty-buffers, emptybuffers
                .word       limit, dolit, BUFFER_MEM_START
                .word       xdo
1:              .word       index, dolit, (~ATTR_BUFFER_UPDATE & 0xFFFFFFFF)
                .word       over, store
                .word       fourplus
                .word       bslashbuf, blank, fill
                .word       bslashbuf, fourplus
                .word       xploop, 1b
                .word       exit

@ +blk   ( -- )         \ select next screen
@: +blk
@      scr @
@      capacity 1- =
@      if
@        0
@      else ;
@        scr @ 1+
@      then
@    scr !
@    restore ;
                COLON       editor_link_address, 0, +blk, plusblk
                .word       scr, at
                .word       capacity, oneminus, equal
                .word       qbranch, 2f
                .word       dolit, 0
                .word       branch, 1f
2:              .word       scr, at, oneplus
1:              .word       scr, store, restore
                .word       exit

@ -blk   ( -- )         \ select previous screen
@: -blk
@    scr @
@    if
@      src @
@    else
@      capacity
@    then
@    1- scr !
@    restore ;
                COLON       editor_link_address, 0, -blk, minusblk
                .word       scr, at
                .word       qbranch, 2f
                .word       scr, at
                .word       branch, 1f
2:              .word       capacity
1:              .word       oneminus, scr, store, restore
                .word       exit

@ bsp  ( -- )
@ : bsp
@     col @
@     if
@       left
@       delete
@     then ;
                COLON       editor_link_address, 0, bsp, bsp
                .word       col, at
                .word       qbranch, bsp1
                .word       cleft, delete
bsp1:           .word       exit

@ : bwrite  ( -- )
@ saveblk  clrmsg ."Stored block#: "
@ scr @ . spause  clrmsg <cxy> ;
                COLON       editor_link_address, 0, bwrite, bwrite
                .word       prev, at, fourplus
                .word       scr, at
                .word       dolit, FALSE
                .word       rslashw
                .word       exit

@ : ?clear  ( -- )        \ clear screen or buffer
@ clrmsg ." * * * clear-out: (b)uffer, (s)creen ? "  key
@ dup emit  upc  dup ascii b =  if drop bclear
@ else ascii s =  if sclear <hom> then  then  clrmsg <cxy> ;
                COLON       editor_link_address, 0, ?clear, qclear
                .word       clrmsg
                .word       dotqp
                .byte       1f - . - 1
                .ascii      "clear: (b)uffer, (s)creen ? "
1:              .align      2, 0
                .word       key
                .word       dupp, emit
                .word       dupp, dolit, 'b', equal
                .word       over, dolit, 'B', equal, orrr
                .word       qbranch, 1f
                .word       drop
                .word       prev, at, fourplus
                .word       bslashbuf, blank, fill
                .word       showblk
                .word       branch, 2f
1:              .word       dupp, dolit, 's', equal
                .word       swap, dolit, 'S', equal, orrr
                .word       qbranch, 2f
@                .word       sclear
2:              .word       clrmsg, xhom
                .word       exit

@ keyvectors array
@ up          ( up curs        )
@ down        ( down curs      )
@ right       ( right curs     )
@ left        ( left curs      )
@ <hom>       ( home           )
@ mode        ( insert         )
@ delete      ( del char       )
@ +blk        ( next blk (PgUP))
@ -blk        ( prev blk (PdDown))
@ ?exit       ( ctrl-q         )
@ bwrite      ( ctrl-w         )
@ ?clear      ( ctrl-c         )
@ htab        ( tab            )
                COLON       editor_link_address, 0, keyvectors, keyvectors
                .word       dovar
                .word       cup
                .word       cdown
                .word       cright
                .word       cleft
                .word       xhom
                .word       mode
                .word       delete
                .word       plusblk
                .word       minusblk
                .word       bsp
                .word       qexit
                .word       bwrite
                .word       qclear
                .word       htab

@ keydo ( n -- )
@ : keydo
@     4*
@     keyvectors +
@     @ execute ;
                COLON       editor_link_address, 0, keydo, keydo
                .word       fourstar
                .word       keyvectors, plus
                .word       at, execute
                .word       exit

@ : editcase  ( flag chr -- flag' )
@     dup
@     0x100 0x10D within    \ Control character?
@     if
@       keydo
@     else
@       dup ' ' '~' within
@       if
@         update            \ Set the UPDATE bit to flag this screen
@                           \  as modified.
@         i/r @
@         if
@           insert
@         else
@           overtype
@         then
@       else
@         drop            \ Unrecognized character.
@         beep
@       then
@     then ;
                COLON       editor_link_address, 0, editcase, editcase
                .word       dupp
                .word       dolit, 0x100, dolit, 0x200, within
                .word       qbranch, 1f
                .word       dolit, 0x100, minus
                .word       keydo, exit
1:              .word       dupp
                .word       dolit, ' ', dolit, '~', within
                .word       qbranch, 2f
                .word       update
                .word       islashr, at
                .word       qbranch, 3f
                .word       insert
                .word       exit
3:              .word       overtype, exit
2:              .word       drop, beep
                .word       exit

@ : editloop  ( -- )
@     0                 \ Flag that will become 1 is we want to exit the loop.
@     begin
@       key mapkey
@       editcase
@       dup
@     until
@     drop ;
@ forth definitions
                COLON       editor_link_address, 0, editloop, editloop
                .word       dolit, 0
1:              .word       key, mapkey
                .word       editcase
                .word       dupp
                .word       qbranch, 1b
                .word       drop
                .word       clrterm
                .word       exit

@ : edinit  ( -- )
@     clrlbuf
@     loadblk
@     clrterm
@     border     \ Draw the border.
@     -1 i/r !   \ Insert is default mode.
@     showmode
@     showblk <hom> ;
                COLON       editor_link_address, 0, edinit, edinit
                .word       cui
                .word       loadblk
                .word       clrterm
                .word       border
                .word       dolit, TRUE, islashr, store
                .word       showmode
                .word       showblk
                .word       xhom
                .word       cuv
                .word       exit

@ edit  ( n -- )
@ : edit
@     capacity <
@     if
@       scr !
@       base @ >r decimal
@       edinit
@       editloop
@     r> base !           \ Restore original base.
@     then ;
                COLON       editor_link_address, 0, edit, edit
                .word       dupp
                .word       capacity, lthan
                .word       qbranch, 1f
                .word       scr, store
                .word       base, at, tor, decimal
                .word       edinit
                .word       editloop
1:              .word       rfrom, base, store
                .word       exit

@ load  ( blk# -- )
@ : load
@     >in @ >r          \
@     #tib @ >r         \
@     tib @ >r          \
@     0 >in !           \ Reset the pointer of the temp buffer.
@     bslashbuf #tib !  \ These are the characters to be parsed. We consider
@                       \  the buffer as one long string b/buff characters long.
@     bladdr #tib 4+ !  \ Starting address of the buffer to parse.
@     begin
@       bl word         \ Get next token and pack it as a string.
@       dup c@          \ Continue until no new word is parsed.
@     while             \ If the length is zero, exit.
@       'eval @execute  \ Execute command (default: $interpret).
@       ?stack          \ Abort if the data stack underflows.
@     repeat
@     r> #tib 4+ !
@     r> #tib !
@     r> >in !;         \
                COLON       editor_link_address, 0, load, load
                .word       inn, at, tor
                .word       ntib, at, tor
                .word       tib, tor
                __break__
                .word       dolit, 0, inn, store
                .word       bslashbuf, ntib, store
                .word       bladdr, ntib, fourplus , store
1:              .word       blank, word
                .word       dupp, cat
                .word       qbranch, 2f
                .word       teval
                .word       atexe
                .word       qstack
                .word       branch, 1b
2:              .word       rfrom, ntib, fourplus, store
                .word       rfrom, ntib, store
                .word       rfrom, inn, store
                .word       exit

@ list  ( blk# -- )
@ : list
@     bladdr dup
@     b/buf + swap      \ 'do' indices.
@     do
@       i 64 _type      \ Print a 64 byte line filtering non-printable
@                       \  characters.
@       64
@     +loop ;           \ Loop through the entire buffer.
                COLON       editor_link_address, 0, list, list
                .word       cui, cr
                .word       bladdr, dupp
                .word       bslashbuf, plus, swap
                .word       xdo
1:              .word       index, dolit, 64, types
                .word       cr
                .word       dolit, 64
                .word       xploop, 1b
                .word       cuv
2:              .word       exit


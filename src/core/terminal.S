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

                .equ        LFF,   10           @ Line feed.
                .equ        CRR,   13           @ Carriage return.
                .equ        BKSPP, 0x7F         @ The mapping of the back space
                                                @  key is 0x7F for most Linux
                                                @  terminals (vt100, vt220).
@ ------------------------------------------------------------------------------
@                               B A S I C  I / O
@ ------------------------------------------------------------------------------
@ ?key ( -- c T | F )
@ Return input character and true, or a false if no input.
@
@ : ?key '?key @execute ;   \ Execute the terminal input routine.
                COLON       forth_link_address, 0, ?key, qkey
                .word       tqkey, atexe, exit

@ key ( -- c )
@ Wait for and return an input character.
@
@ : key begin ?key until ;
                COLON       forth_link_address, 0, key, key
key1:           .word       qkey
                .word       qbranch, key1
                .word       exit

@ emit ( c -- )
@ Send a character to the output device.
@
@ : emit 'emit @execute ;
                CODE        forth_link_address, 0, emit, emit
                m_emit
                m_next
local_temit_var: .word      temit_var

@ cr ( -- )
@ Output a carriage return and a line feed.
@
@ : bl '\r' emit '\n' emit ;
                CODE        forth_link_address, 0, cr, cr
                m_dolit     CRR
                m_emit
                m_dolit     LFF
                m_emit
                m_next

@ bl ( -- 32 )
@ Return 32, the blank character.
@
@ : bl ' ' ;
                CODE        forth_link_address, 0, bl, blank
                m_dolit     ' '
                m_next

@ space ( -- )
@ Send the blank character to the output device.
@
@ : space ' ' emit ;
                CODE        forth_link_address, 0, space, space
                m_dolit     ' '
                m_emit
                m_next

@: beep ( -- )
                COLON       forth_link_address, 0, beep, beep
                .word       dolit, 7, emit
                .word       exit

@ type ( b u -- )
@ Output u characters from b.
@ : type
@       >r          \ Index for the do loop.
@       do
@           dup     \ Make copy of pointer.
@           c@      \ Get character.
@           emit    \ Print
@           1+      \ Increment pointer.
@       loop
@       drop ;      \ Drop pointer.
                CODE        forth_link_address, 0, type, types
                m_forc
                m_bran      2f
1:              m_dupp
                m_cat
                m_emit
                m_oneplus
2:              m_nextc     1b
                m_drop
                m_next

@ >char ( c -- c )
@ Filter non-printing characters.
@
@ : >char
@     dup
@     blank ('~' + 1) within    \ Test for character in printable interval.
@     0=
@     if                  \
@       dup 0x1B xor      \ Test for the ESCAPE character. We want to print
@                         \  it so that the strings will retain their
@                         \  attributes (like color).
@       if                \
@         drop '_'        \ This is not a printable char. Print an underscore.
@       then              \
@     then ;
                COLON       forth_link_address, 0, >char, tchar
                .word       dupp
                .word       blank, dolit, '~' + 1, within, zequ
                .word       qbranch, tchar1
                .word       dupp, dolit, 0x1b, xorr
                .word       qbranch, tchar1
                .word       drop, dolit, '_'
tchar1:         .word       exit

@ _type ( b u -- )
@ Display a string. Filter non-printing characters.
@
@ : _type
@     over +
@     swap
@     do
@       i @
@       >char
@       emit
@     loop ;
                COLON       forth_link_address, 0, _type, utype
                .word       over, plus, swap
                .word       xdo
1:              .word       index, cat, tchar, emit
                .word       xloop, 1b
                .word       exit

@ spaces ( +n -- )
@ Send n spaces to the output device.
@
@ : spaces
@      0 max >r                \ Discard negative counts and use as index.
@      repeat
@          space
@      until ;
                COLON       forth_link_address, 0, spaces, spaces
                .word       dolit, 0, max, tor
                .word       branch, char2
char1:          .word       space
char2:          .word       xnext, char1
                .word       exit

@ -trailing    ( b u -- b u )
@ Adjust the count to eliminate trailing white space.
                COLON       forth_link_address, 0, -trailing, mtrailing
                .word       tor
                .word       branch, dtra2
dtra1:          .word       blank, over, rat, plus, cat, lthan
                .word       qbranch,dtra2
                .word       rfrom, dolit, 1, plus, exit
dtra2:          .word       xnext, dtra1
                .word       dolit, 0, exit

@ chnemit ( ch +n -- )
@ Send n ch characters to the output device.
@
@ : chnemit
@      0 max >r                \ Discard negative counts and use as index.
@      begin
@          dup emit
@      until
@      drop;
                COLON       forth_link_address, 0, chnemit, chnemit
                .word       dolit, 0, max, tor
                .word       branch, chnemit2
chnemit1:       .word       dupp, emit
chnemit2:       .word       xnext, chnemit1
                .word       drop
                .word       exit

@ digit    ( u -- c )
@ Convert digit u to a character.
@ Numbers above 9 will translate to characters starting with 'A'.
@
@ : digit
@       9 swap u<
@       if                  \ If less than 9...
@         'A' - '9' - 1 +
@       then + \ Add alpha offset to numbers above 9.
@       '0' + ;                \ Make it a char.
                COLON       forth_link_address, 0, digit, digit
                .word       dupp, dolit, 9, swap, uless
                .word       qbranch, digit1
                .word       dolit, 'A' - '9' - 1, plus
digit1:         .word       dolit, '0', plus
                .word       exit

@ extract ( n base -- n c )
@ Extract the least significant digit from n.
@
@ : extract
@       0            \ Make n a double for ummod
@       swap         \ Divisor is the base
@       ummod
@       swap         \ Get the remainder, leave the quotient in the stack.
@       digit ;      \ Convert the digit to a character.
                COLON       forth_link_address, 0, extract, extrc
                .word       dolit, 0, swap
                .word       ummod
                .word       swap
                .word       digit
                .word       exit

@ <# ( -- )
@ Initiate the numeric output process.
                COLON       forth_link_address, 0, <#, bdigs
                .word       pad, hld, store, exit

@ # ( u -- u )
@ Extract one digit from u and append the digit to output string.
@
@ : extract base @ extract hold ;
                COLON       forth_link_address, 0, #, dig
                .word       base, at, extrc, hold, exit

@ #s ( u -- 0 )
@ Convert u until all digits are added to the output string.
@
@ : #s
@    repeat # until ;    \ Convert one number.
                COLON       forth_link_address, 0, #s, digs
digs1:          .word       dig
                .word       dupp, qbranch, digs2
                .word       branch, digs1
digs2:          .word       exit

@ #> ( w -- b u )
@ Prepare the output string to be TYPE'd.
                COLON       forth_link_address, 0, #>, edigs
                .word       drop, hld, at
                .word       pad, over, minus, exit@ at-xy ( r c -- )

@ at-xy ( r c -- ) Move the cursor to location (r, c)
@
@ : at-xy
@    base @ >r decimal      \ Save current base and switch to decimal.
@    ESC emit
@    '[' emit
@    swap                  \ X first.
@    <# # #>               \ Turn coordinate number to string.
@    type
@    ';' emit              \ Coordinate separator.
@    <# # #>               \ Y.
@    type
@    'H' emit
@    r> base ! ;           \ Restore original base.
                COLON       forth_link_address, 0, at-xy, atxy
                .word       base, at, tor, decimal
                .word       dolit, ESC, emit
                .word       dolit, '[', emit
                .word       swap
                .word       bdigs, digs, edigs
                .word       types
                .word       dolit, ';', emit
                .word       bdigs, digs, edigs
                .word       types
                .word       dolit, 'H', emit
                .word       rfrom, base, store
                .word       exit

@ clrterm ( -- )
@ Clear the terminal window.
@
                COLON       forth_link_address, 0, clrterm, clrterm
                .word       dotqp
                .byte       clrterm_strend - . -1
                .ascii      "\x1b[2J"
clrterm_strend: .align      2, 0
                .word       exit

@ cuv ( -- )
@ Makes the terminal cursor visible.
@
                COLON       forth_link_address, 0, cuv, cuv
                .word       dotqp
                .byte       cuv_strend - . -1
                .ascii      "\x1b[?25h"
cuv_strend:     .align      2, 0
                .word       exit

@ cui ( -- )
@ Makes the terminal cursor invisible.
@
                COLON       forth_link_address, 0, cui, cui
                .word       dotqp
                .byte       cui_strend - . -1
                .ascii      "\x1b[?25l"
cui_strend:     .align      2, 0
                .word       exit

@ chome ( -- )
@ Sends the cursor to the home space (0,0)
@
                COLON       forth_link_address, 0, chome, chome
                .word       dotqp
                .byte       chome_strend - . -1
                .ascii      "\x1b[0;0H"
chome_strend:   .align      2, 0
                .word       exit

@ cus ( -- )
@ Save cursor position
@
                COLON       forth_link_address, 0, cus, cus
                .word       dotqp
                .byte       cus_strend - . -1
                .ascii      "\x1b[s"
cus_strend:     .align      2, 0
                .word       exit

@ cur ( -- )
@ Restore cursor position.
@
                COLON       forth_link_address, 0, cur, cur
                .word       dotqp
                .byte       cur_strend - . -1
                .ascii      "\x1b[u"
cur_strend:     .align      2, 0
                .word       exit

@ ^h ( bot eot cur -- bot eot cur )
@ Backup the cursor by one character.
                COLON       forth_link_address, 0, ^h, bksp
                .word       tor, over, rfrom, swap, over, xorr
                .word       qbranch, back1
                .word       dolit, BKSPP, techo, atexe, oneminus
                .word       blank, techo, atexe
                .word       dolit, BKSPP, techo, atexe
back1:          .word       exit

@ : mapkey  ( c -- c' )
@   dup
@   ESC =
@   if
@     drop
@     key
@     '[' =
@     if
@       key
@       dup 'A' =                       \ Cursor UP.
@       if
@         drop 0x100 0 +
@       else
@         dup 'B' =                     \ Cursor DOWN.
@         if
@           drop 0x100 1 +
@         else
@           dup 'C' =                   \ Cursor RIGHT.
@           if
@             drop 0x100 2 +
@           else
@             dup 'D' =                 \ Cursor LEFT.
@             if
@               drop 0x100 3 +
@             else
@               dup '1' =
@               if
@                 drop key
@                 dup '~' =             \ Home.
@                 if
@                   drop 0x100 4 +
@                 else
@                   dup '1' =           \ F1
@                   if
@                     drop 0x100 11 +   \ F1 is write buffer.
@                   else
@                     dup '2' =         \ F2
@                     if
@                       drop 0x100 20 + \ F2 is quit.
@                     else
@                       drop 0x100 0 +
@                     then
@                   then
@                 then
@               else
@                 dup '2' =
@                 if
@                   drop key            \ Drop the '2'.
@                   dup '~' =           \ Insert.
@                   if
@                     drop 0x100 23 +
@                   then
@                 else
@                   dup '3' =
@                   if
@                     drop key
@                     dup '~' =         \ Delete.
@                     if
@                       drop 0x100 7 +
@                     then
@                   else
@                     drop 0x100 0 +
@                   then
@                 then
@               then
@             then
@           then
@         then
@       then
@     then
@   else
@     dup BKSPP =
@     if
@       drop 0x100 8 +
@     then
@   then ;
@
                COLON       forth_link_address, 0, mapkey, mapkey
                .word       dupp, dolit, 0x3, equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 12, exit
1:              .word       dupp, dolit, 0x9, equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 13, exit
1:              .word       dupp, dolit, 0x11, equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 10, exit
1:              .word       dupp, dolit, 0x17, equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 11, exit
1:              .word       dupp, dolit, ESC, equal
                .word       qbranch, mapkey1
                .word       drop, key
                .word       dolit, '[', equal
                .word       qbranch, mapkey1
                .word       key
                .word       dupp, dolit, 'A', equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 0, exit
1:              .word       dupp, dolit, 'B', equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 1, exit
1:              .word       dupp, dolit, 'C', equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 2, exit
1:              .word       dupp, dolit, 'D', equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 3, exit

@ Third character.
1:              .word       dupp, dolit, '1', equal
                .word       qbranch, mapkey6

                .word       drop, key
                .word       dupp, dolit, '~', equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 4, exit

1:              .word       dupp, dolit, '1', equal
                .word       qbranch, 1f
                .word       drop, dolit, 0x100 + 0x40, exit

1:              .word       dupp, dolit, '2', equal
                .word       qbranch, mapkey_err
                .word       drop, dolit, 0x100 + 0x41, exit

mapkey6:        .word       dupp, dolit, '2', equal
                .word       qbranch, mapkey7
                .word       drop, key
                .word       dupp, dolit, '~', equal
                .word       qbranch, mapkey_err
                .word       drop, dolit, 0x100 + 5, exit

mapkey7:        .word       dupp, dolit, '3', equal
                .word       qbranch, mapkey8
                .word       drop, key
                .word       dupp, dolit, '~', equal
                .word       qbranch, mapkey_err
                .word       drop, dolit, 0x100 + 6, exit

mapkey8:        .word       dupp, dolit, '5', equal
                .word       qbranch, mapkey9
                .word       drop, key
                .word       dupp, dolit, '~', equal
                .word       qbranch, mapkey_err
                .word       drop, dolit, 0x100 + 7, exit

mapkey9:        .word       dupp, dolit, '6', equal
                .word       qbranch, mapkey_err
                .word       drop, key
                .word       dupp, dolit, '~', equal
                .word       qbranch, mapkey_err
                .word       drop, dolit, 0x100 + 8, exit

mapkey1:        .word       dupp, dolit, BKSPP, equal
                .word       qbranch, mapkey_11
                .word       drop, dolit, 0x100 + 9, exit
mapkey_err:     .word       drop, dolit, -1
mapkey_11:      .word       exit

@ ktap ( bot eot cur c -- bot eot cur )
@ Process a key stroke, CR or backspace.
@ This function is the one used upon boot for the 'tap vector.
@ It is called by the 'accept' function to process keystrokes.
@
@ : ktap
@     dup '\r' xor
@     if
@       '\b' xor if
@         ' ' tap
@       drop                \ Drop the return char.
@       swap drop           \ Drop the address of the last byte of TIB.
@       dup
@     then
@     drop
@     swap
@     drop dup ;            \
                COLON       forth_link_address, 0, ktap, ktap
                .word       dupp, dolit, CRR, xorr
                .word       qbranch, ktap2
                .word       dolit, BKSPP, xorr
                .word       qbranch, ktap1
                .word       blank, tap, exit
ktap1:          .word       bksp, exit
ktap2:          .word       drop, swap, drop, dupp, exit

@ textc ( c -- )
@ Set the text color
@
                COLON       forth_link_address, 0, textc, textc
                .word       dotqp
                .byte       textc_strend - . - 1
                .ascii      "\x1b[3"
textc_strend:   .align      2, 0
                .word       emit
                .word       dolit, 'm', emit
                .word       exit

                COLON       forth_link_address, 0, text-fg-black, txtfgblack
                .word       dolit, 0x30, textc, exit

                COLON       forth_link_address, 0, txt-fg-red, txtfgred
                .word       dolit, 0x31, textc, exit

                COLON       forth_link_address, 0, txt-fg-green, txtfggreen
                .word       dolit, 0x32, textc, exit

                COLON       forth_link_address, 0, txt-fg-yellow, txtfgyellow
                .word       dolit, 0x33, textc, exit

                COLON       forth_link_address, 0, txt-fg-blue, txtfgblue
                .word       dolit, 0x34, textc, exit

                COLON       forth_link_address, 0, txt-fg-magenta, txtfgmagenta
                .word       dolit, 0x35, textc, exit

                COLON       forth_link_address, 0, txt-fg-cyan, txtfgcyan
                .word       dolit, 0x36, textc, exit

                COLON       forth_link_address, 0, txt-fg-white, txtfgwhite
                .word       dolit, 0x37, textc, exit

                COLON       forth_link_address, 0, txt-normal, txtnormal
                .word       dotqp
                .byte       txtnormal_strend - . - 1
                .ascii      "\x1b[0m"
txtnormal_strend: .align    2, 0
                .word       exit

                COLON       forth_link_address, 0, txt-bold, txtbold
                .word       dotqp
                .byte       txtbold_strend - . - 1
                .ascii      "\x1b[1m"
txtbold_strend: .align      2, 0
                .word       exit

                COLON       forth_link_address, 0, txt-italic, txtitalic
                .word       dotqp
                .byte       txtitalic_strend - . - 1
                .ascii      "\x1b[3m"
txtitalic_strend: .align    2, 0
                .word       exit


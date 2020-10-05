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

@ ------------------------------------------------------------------------------
@                               B O O T
@ ------------------------------------------------------------------------------
@ xio        ( a a a -- )
@ Reset the i/o vectors 'expect, 'tap, 'echo and 'prompt.
                COLON       forth_link_address, COMPO, xio, xio
                .word       dolit, accept, texpe, dstor
                .word       techo, dstor, exit

@ hand    ( -- )
@ Select i/o vectors for terminal interface.
                COLON       forth_link_address, 0, hand, hand
                .word       dolit, dotok, dolit, emit
                .word       dolit, ktap, xio, exit

@ i/o        ( -- a )
@ array to store default i/o vectors.
                COLON       forth_link_address, 0, i/o, islo
                .word       dovar
                .word       qrx, txsto

@ console  ( -- )
@ Initiate terminal interface.
@
@ : console
@     i/o           \ Get a pointer to the two in and out routines.
@     2@ '?key 2!   \ Stores the vectors in the '?key and 'emit user variables.
@     hand ;
                COLON       forth_link_address, 0, console, conso
                .word       islo, dat, tqkey, dstor
                .word       hand, exit

@ howdy ( -- )
@ Prints name and version number.
@
@ : howdy
@       cr ."\e[2J\e[HCortexForth v" ...
@       howdy           \ BSP Specific printout.
@       cr cr ;
                COLON       forth_link_address, 0, howdy, howdy
                .word       cr
                .word       dotqp
                .byte       hi_strend - . - 1
                .ascii      "\x1b[2J\x1b[H\x1b[34m\x1b[2m"
                .ascii      "CortexForth v" @ model
                .byte       VER + '0', '.', EXT + '0' @ version
                .byte       '\r', '\n'
hi_strend:      .align      2, 0
                .word       bsp_howdy
                .word       dotqp
                .byte       hi2_strend - . - 1
                .ascii      "\x1b[0m\r\n"
hi2_strend:     .align      2, 0
                .word       cr, cr
                .word       exit

@ .ok ( -- )
@ Display 'ok' only while interpreting.
                COLON       forth_link_address, 0, .ok, dotok
                .word       dolit, inter, teval, at, equal
                .word       qbranch,  1f
                .word       dotqp
                .byte       dotok_strend - . -1
                .ascii      "\x1b[1m\x1b[32m ok\x1b[0m"
dotok_strend:   .align      2, 0
1:              .word       cr, exit

@ preset ( -- )
@ Reset data stack pointer and the terminal input buffer.
@ : preset
@   sp0 @ sp!
@   tibb #tib 4+ + ! ;
                COLON       forth_link_address, 0, preset, prese
                .word       szero, spsto
                .word       dolit, tibb, ntib, fourplus, store
                .word       exit

@ null$    ( -- a )
@ Return address of a null string with zero count.
                COLON       forth_link_address, 0, null$, nulls
                .word       dolit, nulls1
                .word       exit
nulls1:         .word       0

@ catch    ( ca -- 0 | err# )
@ Execute word at ca and set up an error frame for it.
@
@ : catch
@   sp@ >r                     \ Save stack pointer.
@   handler @ >r               \ Save error frame.
@   rp@ handler !              \ Store the new handler address.
@     execute                  \ Execute the word (default is 'eval'.)
@   r> handler !               \ Restore the handler pointer.
@   r> drop                    \ discard saved stack ptr
@   0 ;                        \ Load false flag.
                COLON       forth_link_address, 0, catch, catch
                .word       spat, tor, handl, at, tor
                .word       rpat, handl, store
                .word       execute
                .word       rfrom, handl, store
                .word       rfrom, drop, dolit, 0, exit

@ quit    ( -- )
@ Reset return stack pointer and start text interpreter.
@
@ : quit
@      rp0 @ rp!                    \ Reset the return stack pointer.
@      begin
@        [                          \ Start interpretation.
@        begin
@          query                    \ Get input characters.
@          'eval' catch             \ Execute eval.
@          ?dup
@        until
@        'prompt @ >r
@        console null$ over xor
@        if
@           space count
@           type ."| " ? "
@        then
@        r> dolit dotok xor
@        if dolit err emit then
@        prese
@      again ;
                COLON       forth_link_address, 0, quit, quit
                .word       rzero, rpsto
quit1:          .word       lbrace
quit2:          .word       query
                .word       dolit, eval
                .word       catch

@                .word       hex, dp, at, dot, decimal, cr
@                .word       dolit, context_var, dolit, 64, dump

                .word       qdup
                .word       qbranch, quit2
                .word       tprompt, at, tor
                .word       conso, nulls, over, xorr
                .word       qbranch, quit3
                .word       space
                .word       count
                .word       dotqp
                .byte       quit_strend1 - . -1
                .ascii      "\x1b[31m"
quit_strend1:   .align      2, 0
                .word       types
                .word       dotqp
                .byte       quit_strend - . - 1
                .ascii      " ? \x1b[0m\r\n"
quit_strend:    .align      2, 0
quit3:          .word       rfrom, dolit, dotok, xorr
                .word       qbranch,quit4
                .word       dolit, ESC, emit
quit4:          .word       prese
                .word       cr
                .word       branch, quit1

                CODE        forth_link_address, 0, delay, delay
                movt        WREG1, 0x0050
1:              subs        WREG1, #1
                bne         1b
                m_next

@ cold    ( -- )
@ The hilevel cold start sequence.
@
@ : cold
@     begin
@       hwsetup                         \ Initialize hardware.
@       uzero upp ulast uzero - cmove   \ Copy user variables to RAM.
@       prese                           \ Initialize data stack and TIB.
@       empty-buffers                   \ Write any updated data buffers.
@       0 prev !                        \
@       1 use !                         \
@       'boot @execute                  \ Init IO and print banner.
@       forth                           \ Forth is the context vocabulary.
@       context @ dupp                  \ Initialize search order.
@       current 2!
@       overt                           \ Link
@       quit                            \ Start interpretation.
@     again
                COLON       forth_link_address, 0, cold, cold
cold1:          .word       dolit, _etext_end, dolit, _data
                .word       dolit, _edata
                .word       dolit, _data
                .word       minus
                .word       cmove

                .word       hwsetup
                .word       prese

                .if         COMPILE_EDITOR == 1
                .word       emptybuffers
                .endif

                .word       tboot, atexe

@                .word       forth
@                .word       context, at, dupp
@                .word       current, dstor, overt
@                .word       context, at, current, store
@                .word       overt

@                .word       dolit, list - 1 - 8 - 4
@                .word       dolit, editor_dic_word
@                .word       store
@                .word       hex, context, at, dot, decimal, cr
@                .word       hex, context, at, at, dot, decimal, cr

@                .word       also, editor

@                .word       dolit, 0, block

                .word       quit
                .word       branch, cold1

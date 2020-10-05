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

@ setdolst ( ca --- )
                CODE        forth_link_address, 0, setdolst, setdolst
                ldr         DOLST_ADDR, [IPP], #4
                m_next

@ -thumb ( a --- a )
@ Remove the ARM "Thumb" bit from the execution address on TOS.
@
@ : -thumb
@     ~1 and ;
                COLON       forth_link_address, 0, -thumb, mthumb
                .word       dolit, ~1, andd
                .word       exit

                COLON       forth_link_address, 0, tinfo, tinfo
@ tinfo ( --- )
@ Prints out information while tracing a word.
@
@ : tinfo
@     cus cui       \ Save cursor position and make it invisible.
@     3 80 atxy     \
@     16 spaces     \ Clear up 16 spaces
@     3 80 atxy     \
@     r> r@ swap >r \ Get the address of the executiion token within the
@                   \  traced word.
@     -thumb        \ Remove Thumb bit.
@     2 -           \ Here we need to be sure that we are pointing to the
@                   \  execution token list past the 'bx r8' instruction.
@     dup h@        \ Get token.
@     ASM_DOLST -   \ Is this the 'bx r8' instruction.
@     if
@       2 +         \ Move to the execution token areas.
@     then
@     cfa>nfa       \ Get NFA of word.
@     txtblue .id txtnormal \ Print name.
@     begin
@       key         \ Get user input
@       '+' =
@     until
@     cur cuv       \ Restore the cursor and make it visible.
@
@
                .if 0
tinfo:          .word       cus, cui
                .word       dolit, 3, dolit, 80, atxy
                .word       dolit, 16, spaces
                .word       dolit, 3, dolit, 80, atxy
                .word       rfrom, rat, swap, tor
                .word       mthumb
                .word       dolit, 2, minus
                .word       dupp, hat
                .word       dolit, ASM_DOLST, minus
                .word       qbranch, tinfo1
                .word       dolit, 2, plus
tinfo1:         .word       cfa2nfa
                .word       txtfgblue
                .word       dotid
                .word       txtnormal
tinfo2:         .word       key
                .word       dolit, '+', equal
                .word       qbranch, tinfo2
                .word       cur, cuv
                .word       exit
                .else
tinfo:          .word       dolit, 0, drop, exit
                .endif

@ tdolist ( -- )
@ Process colon list while tracing.
@ This is a frankenword, that starts out as a code word, runs a colon section
@  only to end as a code word. The colon portion is where we print out all the
@  debug informaiton.
                CODE        forth_link_address, 0, tdolist, tdolist

@ Here IPP points to the execution token of the word that follows 'execute'
@  within the 'trace' word. This address must be saved in the return stack
@  so we can return to it when we execute the 'exit' in the word being traced.
                PUSHH       IPP, RSP

@ The link register points to the first execution token of the word to trace.
@ We also must save this register in the return stack because IPP will be be
@ temporarily hijacked to execute the code that prints out the stack
@ information.
@ We add one because the lr register already has bit 0 set (Thumb bit) and by
@  adding one we align the address to a word boundary.
                add         IPP, lr, #1
                PUSHH       IPP, RSP

@ This is the address to which we will return once the code that prints out the
@  trace information is done. We need to add a second level of indirection
@  (through the use of tdolist_ptr_new) to account for the 'exit' that
@  terminates the 'tinfo' word and the Thumb bit.
                adr         IPP, dolist_ptr_new
                PUSHH       IPP, RSP

@ For the section of Forth code that will print out the debug information we
@  will return to the original dolst code, so we avoid recursions. The trace
@  dolst will be reactivated once the debug info has been printed.
                ldr         DOLST_ADDR, dolist_ptr_orig
                adr         IPP, tinfo
                m_next

                .align      2, 0
tdolst_return:  adr         DOLST_ADDR, tdolist
                POPP        IPP, RSP
                m_next
dolist_ptr_orig:.word       dolist
dolist_ptr_new: .word       tdolst_return + 1

@ trace ( -- )
@
@ : trace
@     blank word
@     find
@     if
@       setdolst tdolst
@       execute
@       setdolst dolst
@     else
@       ." Unknown word "       \ Print error message.
@       .id                     \ Print unknown word.
@     then ;
                COLON       forth_link_address, 0, trace, trace
                .word       blank, word, find
                .word       qbranch, trace1
                .word       lfa2cfa
                .word       setdolst, tdolist
                .word       execute
                .word       setdolst, dolist
trace1:         .word       dotqp
                .byte       trace_strend1 - . -1
                .ascii      "\x1b[1m\x1b[31m Unknown word: "
trace_strend1:  .align      2, 0
                .word       dotid
                .word       dotqp
                .byte       trace_strend2 - . -1
                .ascii      "\x1b[0m"
trace_strend2:  .align      2, 0
                .word       exit

@ see-addr ( -- )
@
@ : see-addr
@     base @ >r hex
@     '$' emit
@     over .
@     space dup
@     -thumb .
@     r> base ! ;
                COLON       forth_link_address, 0, see-addr, see_addr
                .word       base, at, tor, hex
                .word       dolit, '$', emit, over, dot
                .word       space, dupp, mthumb, dot
                .word       rfrom, base, store
                .word       exit

@ see ( -- ; <string> )
@ A very simple colon word decompiler.
@
@ : see
@   bl word                         \ Parse the next word delimited by a blank.
@   find                            \ return CFA word to see.
@   if                              \ Word found in dictionary?
@     lfa>nfa                       \
@     dup c@                        \ NFA.
@     ASMWR and 0=                  \ Is it a CODE word?
@     if                            \ Make sure this is a colon definition
@       nfa>cfa
@       4+                          \ Skip past ENTER to reach the code pointers.
@       begin
@         dup @                     \ Read code pointer.
@         dup dolit =               \ Is it the dolit word?
@         if
@           over cr                 \ Get address of word.
@           base @ >r hex           \ Address is always printed in HEX.
@           '$' emit .              \
@           -thumb                  \ Mask off thumb bit.
@           space .                 \ Print the dolit execution token.
@           r> base !               \ Restore base.
@           4+ dup @                \ Find the number to print.
@           space dup .             \ print it.
@           dup
@           ' ' '~' 1+ within
@           if
@             ." '" emit ."'"
@           else
@             drop
@           then
@           4+                      \ Reach the next code pointer.
@         else
@           dup @                   \ Read code pointer.
@           dup dotqp =             \ Is it the ."| word?
@           over aborq =            \ Is it the abort" word?
@           or
@           if
@             see-addr
@             -thumb                \ Mask off thumb bit.
@             space                 \
@             cfa>nfa .id           \ Print the NFA.
@             4+                    \ Reach start of the string to print.
@             dup space .id         \ Print string.
@             '"' emit              \ Terminate the string.
@             nfa>cfa               \ Get to next code pointer.
@           else
@             dup qbranch =         \ Is it ?branch...
@             over branch =         \ or branch?
@             or                    \ Either one is treated here.
@             over xploop =         \ or xploop?
@             or                    \
@             over xloop =          \ or xloop?
@             or                    \
@             if
@               see-addr
@               -thumb              \ Mask off thumb bit.
@               space               \
@               cfa>nfa .id         \ Print the NFA.
@               4+ dup @            \ Destination address.
@               base @ >r hex       \
@               space '$' emit .    \ Print number
@               r> base !           \
@               4+
@             else
@               -thumb dup          \ Mask off thumb bit.
@               cfa>nfa ?dup        \ CFA->NFA
@               if                  \ Does the word exist?
@                 >r                \ Save to avoid another call to cfa>nfa.
@                 see-addr          \ Print out address and execution token.
@                 drop              \ Drop execution token.
@                 r> space .id      \ Print word name.
@                 4+                \ Reach next CFA to see.
@               else
@                 2drop drop exit   \ If not, leave.
@               then
@             then
@           then
@         then
@       again
@     else
@       drop                  \ Drop LFA.
@       ." Code word"         \ Print error message.
@     then
@   else
@     drop                    \ Drop LFA pointer.
@     ." Unknown word"        \ Print error message.
@   then ;
                COLON       forth_link_address, 0, see, see
                .word       blank, word, find
                .word       qbranch, see3
                .word       lfa2nfa
                .word       dupp, cat, dolit, ASMWR, andd, zequ
                .word       qbranch, see4
                .word       nfa2cfa, fourplus
see1:           .word       cr
                .word       dupp, at
                .word       dupp, dolit, dolit, equal
                .word       qbranch, see5
                .word       see_addr
                .word       drop
                .word       fourplus, dupp, at
                .word       space, dupp, dot
                .word       dupp
                .word       dolit, ' ', dolit, '~' + 1, within
                .word       qbranch, see8
                .word       dotqp
                .byte       see_strend3 - . -1
                .ascii      " '"
see_strend3:    .align      2, 0
                .word       emit
                .word       dotqp
                .byte       see_strend4 - . -1
                .ascii      "'"
see_strend4:    .align      2, 0
                .word       branch, see9
see8:           .word       drop
see9:           .word       fourplus
                .word       branch, see1
see5:           .word       dupp, dolit, dotqp, equal
                .word       over, dolit, aborq, equal
                .word       orrr
                .word       qbranch, see6
                .word       see_addr
                .word       mthumb, space, cfa2nfa, dotid
                .word       fourplus, dupp, space, dotid
                .word       dolit, '"', emit
                .word       nfa2cfa
                .word       branch, see1
see6:           .word       dupp, dolit, qbranch, equal
                .word       over, dolit, branch, equal
                .word       orrr
                .word       over, dolit, xploop, equal
                .word       orrr
                .word       over, dolit, xloop, equal
                .word       orrr
                .word       qbranch, see7
                .word       see_addr
                .word       mthumb, cfa2nfa, space, dotid
                .word       fourplus, dupp, at
                .word       base, at, tor, hex
                .word       space, dolit, '$', emit, dot
                .word       rfrom, base, store
                .word       fourplus
                .word       branch, see1
see7:           .word       mthumb, dupp, cfa2nfa, qdup
                .word       qbranch, see2
                .word       tor
                .word       see_addr, drop
                .word       rfrom, space, dotid
                .word       fourplus
                .word       branch, see1
see2:           .word       ddrop, drop
                .word       exit
see4:           .word       drop
                .word       dotqp
                .byte       see_strend2 - . -1
                .ascii      "\x1b[1m\x1b[31m Code word\x1b[0m"
see_strend2:    .align      2, 0
                .word       exit
see3:           .word       drop
                .word       dotqp
                .byte       see_strend1 - . -1
                .ascii      "\x1b[1m\x1b[31m Unknown word\x1b[0m"
see_strend1:    .align      2, 0
                .word       exit

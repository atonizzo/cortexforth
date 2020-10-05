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

@ if ( -- a )
@ begin a conditional branch structure.
                COLON       forth_link_address, COMPO+IMMED, if, iff
                .word       compile, qbranch, here
                .word       dolit, 0, comma, exit

@ then    ( a -- )
@ Terminate a conditional branch structure.
                COLON       forth_link_address, COMPO+IMMED, then, thenn
                .word       here, swap, store, exit

@ else    ( a -- a )
@ Start the false clause in an if-else-then structure.
@
@ : else
@     compile branch
@     here          \ This is the target address for branch filled by 'then'.
@     0 ,           \ Empty placeholder.
@     swap          \ Swap the 'if' address with the 'else' one.
@     here          \ This is addres of the word just past the 'else' token.
@     swap !        \ Store the target for 'if'
                COLON       forth_link_address, COMPO+IMMED, else, elsee
                .word       compile, branch
                .word       here, dolit, 0, comma
                .word       swap
                .word       here, swap, store, exit
                .word       exit

@ for ( -- a )
@ Start a FOR-NEXT loop structure in a colon definition.
                COLON       forth_link_address, COMPO+IMMED, for, for
                .word       compile, tor, here, exit

@ (next) ( -- )
@ Run time code for the single index loop.
@ : next ( -- ) \ hilevel model
@    r> r> dup if 1 - >r @ >r exit then drop cell+ >r ;
                CODE        forth_link_address, COMPO, xnext, xnext
                m_donext
                NEXT

@ next ( a -- )
@ Terminate a FOR-NEXT loop structure.
                COLON       forth_link_address, COMPO+IMMED, next, next
                .word       compile, xnext, comma, exit

@ begin ( -- a )
@ Start an infinite or indefinite loop structure.
@
@ : begin here ;
                COLON       forth_link_address, COMPO+IMMED, begin, begin
                .word       here, exit

@ until ( a -- )
@ Terminate a begin-until indefinite loop structure.
@
@ : until compile ?branch , ;
                COLON       forth_link_address, COMPO+IMMED, until, until
                .word       compile, qbranch, comma, exit

@ again    ( a -- )
@ Terminate a begin-again infinite loop structure.
                COLON       forth_link_address, COMPO+IMMED, again, again
                .word       compile, branch, comma, exit

@ while ( a -- a a )
@ Conditional branch out of a begin-while-repeat loop.
@
@ : while
@     compile ?branch
@     here                  \ Word for address to branch to.
@     0 ,                   \ Empty placeholder.
@     swap ;                \ Swap 'while' address with 'begin' one. Now TOS
@                           \  is 'begin'.
                COLON       forth_link_address, COMPO+IMMED, while, while
                .word       compile, qbranch, here
                .word       dolit, 0, comma
                .word       swap, exit

@ repeat ( -- )
@
@ : repeat
@     compile branch        \
@     ,                     \ Compile the branch back to 'begin'.
@     here                  \ Address of target for 'while' ?branch.
@     swap , ;              \ Compile it.
                COLON       forth_link_address, COMPO+IMMED, repeat, repeat
                .word       compile, branch, comma
                .word       here, swap, comma
                .word       exit

@ (do) ( n b -- ) Runtime code for 'do'.
@
@ : do
@    swap >r                \ Push limit to return stack.
@    >r ;                   \ Push starting value to return stack.
                CODE        forth_link_address, COMPO, (do), xdo
                m_xdo
                m_next

@ do ( n2 n1 -- a1 0) Compile time code for 'do'.
@
@ : do
@       compile (do)
@       here            \ The 'loop' word needs an address to branch back to
@       0               \ 0 signals that this is a 'do' command.
@       1 ;             \ Counter of how many 'leave' and 'do' command the
@                       \ 'loop' command is expected to resolve.
                COLON       forth_link_address, COMPO+IMMED, do, do
                .word       compile, xdo
                .word       here
                .word       dolit, 0
                .word       dolit, 1
                .word       exit

@ (?do) ( n b -- ) Runtime code for '?do'.
@
                CODE        forth_link_address, COMPO, (?do), xqdo
                m_xqdo
                m_next

@ ?do ( n2 n1 -- a1 a2 1) Compile time code for '?do'.
@
@ : ?do
@        compile (?do)
@        0 ,            \ Placeholder word for jump address.
@        here           \ Target address for 'loop'.
@        1              \ Used by LOOP to tell DO from ?DO.
@        1 ;            \ Used by LOOP to tell how many addresses to resolve.
                COLON       forth_link_address, COMPO+IMMED, ?do, qdo
                .word       compile, xqdo
                .word       here
                .word       dolit, 0, comma
                .word       here
                .word       dolit, 1
                .word       dolit, 1
                .word       exit

@ (leave) ( -- n ) Runtime code for LEAVE.
                CODE        forth_link_address, COMPO, xleave, xleave
                m_leave
                m_next

@ leave ( -- a1 2)
@ : leave
@        compile (leave)
@        >r             \ Save the counter with loop pairs.
@        here           \ Target address for 'loop'.
@        0 ,            \ Placeholder word for jump address.
@        2              \ Marker for 'leave'.
@        r> 1+ ;        \ Increment the loop pair counter.
                COLON       forth_link_address, COMPO, leave, leave
                .word       compile, xleave
                .word       tor
                .word       here
                .word       dolit, 0, comma
                .word       dolit, 2
                .word       rfrom, oneplus
                .word       exit

@ (loop) ( n2 n1 -- ) Runtime code for LOOP.
                CODE        forth_link_address, COMPO, (loop), xloop
                m_xloop
                m_next

@ This code is common to 'loop' and '+loop' with the exception of the loop
@  token itself. It is then written as a macro, so changes are immediately
@  reflected on both words.
                .macro      loop_body loop_type
                .word       oneminus
                .word       tor
3:              .word       dupp, zequ
                .word       qbranch, 1f
                .word       drop
                .word       compile, \loop_type, comma
                .word       branch, 2f
1:              .word       dupp, dolit, 1, equal
                .word       qbranch, 4f
                .word       drop
                .word       compile, \loop_type, comma
                .word       here, swap, store
                .word       branch, 2f
4:              .word       dupp, dolit, 2, equal
                .word       qbranch, 5f
                .word       drop
                .word       here, dolit, 8, plus
                .word       swap, store
                .word       branch, 2f
5:              .word       throw
                .word       exit
2:              .word       xnext, 3b
                .endm

@ loop ( n2 n1 -- ) Compile time code for LOOP.
@
@ : loop
@     1-                    \ Decrement the marker count.
@     for
@       dup 0=
@       if                  \ Is this a 'do'?
@         drop              \ Drop marker.
@         compile xloop     \ Is this a LOOP for DO.
@         ,                 \ Compile the loop target.
@       else
@         dup 1 =
@         if                \ Is this a '?do'?
@           drop            \ Drop marker.
@           here >r         \ Save dp.
@           compile xloop   \ Is this a LOOP for DO.
@           ,               \ Compile the loop target.
@           rfrom swap !    \ Store jump for ?do.
@         else
@           dup 2 =
@           if              \ Is this a 'leave'?
@             drop          \ Drop marker.
@             here 8 +      \ Skip the 'loop' token plus the destination word.
@             swap !        \ Store jump for 'leave'.
@           else
@             throw
@           then
@         then
@       then ;
                COLON       forth_link_address, COMPO+IMMED, loop, loop
                loop_body   xloop
                .word       exit

@ (+loop) ( n2 n1 -- ) Runtime code for +LOOP.
                CODE        forth_link_address, COMPO, (\+loop), xploop
                m_xploop
                m_next

@ +loop ( n2 n1 -- ) Compile time code for +LOOP.
@
@ : until compile ?branch , ;
                COLON       forth_link_address, COMPO+IMMED, \+loop, ploop
                loop_body   xploop
                .word       exit

@ i ( -- n )
                CODE        forth_link_address, COMPO, i, index
                m_i
                m_next

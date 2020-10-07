@ Copyright [2018-2020] Anthony Tonizzo (atonizzo@gmail.com)
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
@                    N A M E   C O M P I L E R
@ ------------------------------------------------------------------------------
@ $,n ( na -- )
@ Build a new dictionary name using the string at na.
@ Enters with the address in memory where the name resides which will become
@  the NFA of the new word.
@
@ : $,n
@   dup c@
@   if
@       ?unique             \ Display a warning message if the word already
@                           \  exists.
@       dup nfa>lfa dup     \ Compute LFA.
@       last !              \ Save na for vocabulary link
@       current @ @         \ Update the 'current' pointer with the lfa of this
@                           \  word.
@       swap !              \ Store the LFA of the new word.
@       nfa>cfa dp !        \ Find the pointer to the code area and update the
@                           \ data pointer with it.
@   then
@       $"| " name"
@       throw
@   else ;
                make_link   forth_link_address
                .byte       3
                .ascii      "$,n"
                .align      2, 0
                .equ        sname, . + 1
                ENTER
                .word       dupp, cat
                .word       qbranch, pnam1
                .word       qunique
                .word       dupp, nfa2lfa, dupp
                .word       last, store
                .word       current, at, at
                .word       swap, store
                .word       nfa2cfa, dp, store
                .word       exit
pnam1:          .word       strqp
                .byte       sname_strend - . - 1
                .ascii      " \x1b[31mname\x1b[0m"
sname_strend:   .align      2, 0
                .word       throw

@ ?unique    ( a -- a )
@ Display a warning message if the word already exists.
@
                COLON       forth_link_address, 0, ?unique, qunique
                .word       dupp, find
                .word       qbranch, uniq1
                .word       dotqp
                .byte       uniqu_strend - . - 1
                .ascii      " \x1b[31mredefines\x1b[0m "
uniqu_strend:   .align      2, 0
                .word       over, count, types
uniq1:          .word       drop, exit

@ literal ( w -- )
@ Compile TOS to code dictionary as an integer literal.
@ : literal
@   compile dolit , ;
                COLON       forth_link_address, IMMED, literal, literal
                .word       compile, dolit, comma, exit

@ c, ( c -- )
@ Compile an 8 bit integer into the code dictionary.
@
@ : c,
@   here
@   dup 1+ dp !      \ Update DP.
@   c! ;             \ Store the character at HERE.
                make_link   forth_link_address
                .byte       2
                .ascii      "c,"
                .align      2, 0
                .equ        ccomma, . + 1
                ENTER
                .word       here, dupp, oneplus
                .word       dp, store, cstore, exit

@ h, ( h -- )
@ Compile an 16 bit integer into the code dictionary.
@
@ : h,
@   here
@   dup 2+ dp !      \ Update DP.
@   h! ;             \ Store the character at HERE.
                make_link   forth_link_address
                .byte       2
                .ascii      "h,"
                .align      2, 0
                .equ        hcomma, . + 1
                ENTER
                .word       here, dupp, twoplus
                .word       dp, store, hstore, exit

@ , ( w -- )
@ Compile a 32 bit integer into the code dictionary.
@
@ : ,
@   here
@   dup 4+ dp !         \ Update DP.
@   ! ;                 \ Store the word at HERE.
                make_link   forth_link_address
                .byte       1
                .ascii      ","
                .align      2, 0
                .equ        comma, . + 1
                ENTER
                .word       here, dupp, fourplus
                .word       dp, store, store, exit

@ [char] ( a -- )
@ Compile a dolit followed by the character following the word.
@
@ : [char]
@     bl word             \ Parse the next word delimited by a blank.
@     c@ dup              \ Read length of parsed word
@     1 =
@     if
@       1+                \ Advance pointer.
@       c@                \ Get char value.
@       literal           \ Compiler the literal.
@     else
@       trow
@     then ;
                COLON       forth_link_address, COMPO+IMMED, [char], schar
                .word       blank, word
                .word       dupp, cat
                .word       dolit, 1, equal
                .word       qbranch, schar1
                .word       oneplus, cat
                .word       exit
schar1:         .word       throw

@ [compile] ( a -- )
@ Compile next word to code dictionary as a token or literal.
@
@ : [compile]
@     find ?dup
@     if
@       1 =                 \ Immediate word?
@       if
@         lfa>cfa execute   \ Execute the word immediately.
@       else
@         lfa>cfa 1 or      \ Add thumb bit to address.
@         ,                 \ Store.
@       then
@     else
@       'number @execute    \ Is it a number?
@       if
@         literal           \ Compile a literal.
@       else
@         trow
@       then
@     then ;
                COLON       forth_link_address, 0, [compile], scomp
                .word       find
                .word       qdup
                .word       qbranch, scom2
                .word       dolit, 1, equal
                .word       qbranch,  scom1
                .word       lfa2cfa, execute, exit
scom1:          .word       lfa2cfa, dolit, 1, orrr
                .word       comma, exit
scom2:          .word       tnumb, atexe
                .word       qbranch, scom3
                .word       literal, exit
scom3:          .word       throw

@ compile ( -- )
@ Compile the next address in colon list to code dictionary.
@
@ : compile
@   r>              \ Pointer to word following 'compile'.
@   dup @           \ Word to write in the definition.
@   ,               \ Store in word definition.
@   4+ r>;          \ Move pointer and store back to RSP.
                COLON       forth_link_address, COMPO, compile, compile
                .word       rfrom, dupp, at, comma
                .word       fourplus, tor, exit

@ [ ( -- )
@ Start the text interpreter.
@
@ : [ inter 'eval ! ;
                COLON       forth_link_address, IMMED, [, lbrace
                .word       dolit, inter, teval, store, exit

@ ] ( -- )
@ Start compiling the words in the input stream.
@
@ : ] literal scomp 'eval ! ;
                COLON       forth_link_address, 0, ], rbrace
                .word       dolit, scomp, teval, store, exit

@ overt ( -- )
@ Link a new word into the current vocabulary.
@
@ : overt
@     last @
@     current @ ! ;
                COLON       forth_link_address, 0, overt, overt
                .word       last, at, current, at, store, exit

@ create ( -- ; <string> )
@ Compile a new COLON word without allocating code space other than for the
@  DOCOL opcode (ENTER).
@
@ : create
@     here aligned dp ! \ Align the dp pointer to a word boundary.
@     bl word           \ Parse the next word and copy it to the name space.
@     $,n               \ Build a new dictionary name using the address at TOS.
@     overt
@     0x47C0 h,         \ Compile the DOCOL code (0x47C0 'bx r8').
@     0 h, ;            \ Align to a word boundary by padding with 0.
                COLON       forth_link_address, 0, create, create
                .word       here, aligned, dp, store
                .word       blank, word
                .word       sname
                .word       overt
                .word       dolit, ASM_DOLST, hcomma
                .word       dolit, 0, hcomma
                .word       exit

@ variable    ( -- ; <string> )
@ Compile a new variable initialized to 0.
@
@ : variable
@     create        \ Create colon header.
@     'dovar' ,     \ Compile 'dovar'.
@     0 , ;         \ Initialize variable to 0.
                COLON       forth_link_address, 0, variable, varia
                .word       create
                .word       dolit, dovar, comma
                .word       dolit, 0, comma
                .word       exit

@ constant    ( -- ; <string> )
@ Compile a new constant intialized by TOS.
@
@ : constant
@     here aligned dp ! \ Align the dp pointer to a word boundary.
@     bl word           \ Parse the next word and copy it to the name space.
@     $,n               \ Build a new dictionary name using the address at TOS.
@     overt             \ Link the word to the 'current' dictionary.
@     0x47C0 h,         \ Compile the DOCOL code (0x47C0 'bx r8').
@     0 h,              \ Align to a word boundary by padding with 0.
@     doconst ,         \ Compile the 'doconst' code.
@     , ;               \ Store the constant value.
                COLON       forth_link_address, 0, constant, const
                .word       here, aligned, dp, store
                .word       blank, word, sname, overt
                .word       dolit, ASM_DOLST, hcomma
                .word       dolit, 0, hcomma
                .word       dolit, doconst, comma
                .word       comma
                .word       exit

@ : ( -- ; <string> )
@ Start a new colon definition using next word as its name.
@
@ : :
@     here aligned dp ! \ Align the dp pointer to a word boundary.
@     bl word           \ Parse the next word and copy it to the name space.
@     $,n               \ Build a new dictionary name using the address at TOS.
@     0x47C0 h,         \ Compile the DOCOL code (0x47C0 'bx r8').
@     0 h,              \ Align to a word boundary by padding with 0.
@     ] ;               \ Store the constant value.
                COLON       forth_link_address, 0, :, colon
                .word       here, aligned, dp, store
                .word       blank, word
                .word       sname
                .word       dolit, ASM_DOLST, hcomma
                .word       dolit, 0, hcomma
                .word       rbrace, exit

@ ; ( -- )
@ Terminate a colon definition.
                make_link   forth_link_address
                .byte       IMMED+COMPO+1
                .ascii      ";"
                .align      2, 0
                .equ        semicolon, . + 1
                ENTER
                .word       compile, exit, lbrace, overt
                .word       exit

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
@                         I N T E R P R E T E R
@ ------------------------------------------------------------------------------

@ abort"    ( f -- )
@ Run time routine of ABORT" . Abort with a message.
@ We need to create this header by hand, since " is used for strings and that
@  confuses the assembler.
@
@ : abort"
@     if
@         do$ throw
@     then
@     do$ drop;
                make_link   forth_link_address
                .byte       COMPO + 6
                .ascii      "abort\""
                .align      2, 0
                .equ        aborq, . + 1
                ENTER
                .word       qbranch, abor1
                .word       dostr, throw
abor1:          .word       dostr, drop
                .word       exit

@ ?stack    ( -- )
@ Abort if the data stack underflows.
                COLON       forth_link_address, 0, ?stack, qstack
                .word       depth
                .word       zless
                .word       aborq
                .byte       qstac_strend - . - 1
                .ascii      "\x1b[31m underflow\x1b[0m"
qstac_strend:   .align      2, 0
                .word       exit

@ pack$ ( b u a -- a )
@ Build a counted string with u characters from b. Null fill.
@
@ : pack$ ( b u a -- a )    \ null fill
@   dup >r                  \ Save the destination address.
@   over
@   dup
@   3 and                   \ Remainder of division by 4.
@   -                       \ Subtract the remainder of the division of
@                           \  the length by 4 to the name length. This gives
@                           \  us the number of bytes in the name that will fit
@                           \  into one of more 32 bit words.
@                           \  The rest must be filled with 0s.
@   over +                  \ Add count to address.
@   0 swap !                \ Fill the unused bytes in the string with 0.
@   2dup c!                 \ Store the word length.
@   1+                      \ Advance counter.
@   swap cmove              \ Copy the name string.
@   r> ;                    \ Return the address of the start of the string.
                CODE        forth_link_address, 0, pack$, packs
                m_dupp
                m_tor
                m_over
                m_dupp
                m_dolit     3
                m_andd
                m_minus
                m_over
                m_plus
                m_dolit     0
                m_swap
                m_store
                m_ddup
                m_cstore
                m_oneplus
                m_swap
                m_cmove
                m_rfrom
                m_next

@ digit? ( c base -- u t )
@ Convert a character to its numeric value. A flag indicates success.
@
@ : digit?
@     >r                \ Save base.
@     upcase            \ Convert char to upper case.
@     '0' -             \ Remove ASCII offset.
@     9 over <          \
@     if
@       7 -             \ Subtract '@' - '9' offset.
@       dup 10 -
@     then
                COLON       forth_link_address, 0, digit?, digtq
                .word       tor, upcase
                .word       dolit, '0', minus
                .word       dolit, 9, over, lthan
                .word       qbranch, dgtq1
                .word       dolit, 7, minus
                .word       dupp, dolit, 10, lthan, orrr
dgtq1:          .word       dupp, rfrom, uless, exit

@ number?    ( a -- n t | a f )
@ Convert a number string to integer. Push a flag on tos.
@
@: number? ( a -- n t | a f )
@  base @ >r
@  0                         \ Here we accumulate the result.
@  over count ( a 0 b n)     \ Get the count of bytes to convert.
@  over c@ '$' =             \ Is it a hex number?
@  if
@    hex
@    swap 1+                 \ Move past the '$' sign.
@    swap 1-                 \ Decrement character count.
@  then ( a 0 b' n')
@  over c@ '-' = >r ( a 0 b n) \ Check if number if negative and save sign.
@  swap r@ -                 \ Decrease the total length by 1 if the number
@                            \  was positive (negative sign character), do
@                            \  for positive numbers.
@  swap r@ +                 \ Advance pointer past the - sign for a negative
@                            \  number, do nothing for positive number.
@  ?dup
@  if
@    1- ( a 0 b n)           \ Use length as counter for 'for-loop'.
@    for
@      dup >r                \ Save pointer.
@      c@ base @ digit?      \ Is the character a figit of the chosen base?
@      while swap base @ * +  r> 1 +
@    next
@    drop r@ ( b ?sign) if negate then swap
@      else r> r> ( b index) 2drop ( digit number) 2drop 0
@      then dup
@  then r> ( n ?sign) 2drop r> base ! ;

                COLON       forth_link_address, 0, number?, numbq
                .word       base, at, tor, dolit, 0, over, count
                .word       over, cat
                .word       dolit, '$', equal
                .word       qbranch, numq1
                .word       hex, swap, oneplus
                .word       swap, oneminus
numq1:          .word       over, cat, dolit, '-', equal, tor
                .word       swap, rat, minus
                .word       swap, rat, plus, qdup
                .word       qbranch, numq6
                .word       oneminus, tor
numq2:          .word       dupp, tor, cat, base, at
                .word       digtq
                .word       qbranch, numq4
                .word       swap, base, at, star, plus, rfrom
                .word       oneplus
                .word       xnext, numq2
                .word       rat, swap, drop
                .word       qbranch, numq3
                .word       twocomp
numq3:          .word       swap
                .word       branch, numq5
numq4:          .word       rfrom, rfrom, ddrop, ddrop, dolit, 0
numq5:          .word       dupp
numq6:          .word       rfrom, ddrop
                .word       rfrom, base, store, exit

@ $interpret ( a -- )
@ Interpret a word. If failed, try to convert it to an integer.
@ Enters with the address of the string to interpret, preceeded by length.
@ This string is in located in the first available RAM memory.
@ This is called, via the 'eval vector, to interpret the characters input by
@  the user.
@
@ : interpret
@     find
@     ?dup
@     if                      \ Name defined?
@       dup                   \ Make copy of CFA for 'execute'.
@       lfa>nfa               \ LFA->NFA of word.
@       c@ COMPO and          \ Check for compile only bit.
@       abort" "compile only"
@       nfa>cfa execute       \ If not, execute word.
@     else
@       'number @execute      \ Convert number (default is 'number?')
@       if                    \ if not a number, throw.
@         exit
@       then
@         throw
@       else
@     then ;
                COLON       forth_link_address, 0, $interpret, inter
                .word       find
                .word       qbranch, inte1
                .word       lfa2nfa
                .word       dupp
                .word       cat, dolit, COMPO, andd
                .word       aborq
                .byte       inter_strend - . - 1
                .ascii      "\x1b[1m\x1b[31mcompile only\x1b[0m"
inter_strend:   .align      2, 0
                .word       nfa2cfa
                .word       execute
                .word       exit
inte1:          .word       tnumb, atexe
                .word       qbranch, inte2
                .word       exit
inte2:          .word       throw

@ -parse ( b u c -- b u delta ; <string> )
@ Enters with:
@          b : Address of first byte of string to parse.
@          u : Maximum number of characters to parse
@          c : Delimiter character.
@ Exits with:
@          b : Address of first byte of string to parse.
@          u : Length of the string.
@          d : Total number of characters parsed (including separators).
@ Scan string delimited by c. Return found string and its offset.
@
@ : -parse
@     tmp !                 \ Store the demiliter.
@     over >r               \ Save a copy of the pointer of the next byte to
@                           \   parse.
@     dup
@     if                    \ If the number of characters to parse is 0, exit.
@       1-                  \ Subtract one from the count.
@       tmp @ bl =
@       if                  \ If the separator is a blank
@         for               \ Save the character count.
@           bl
@           over c@         \ Read next character to parse.
@           - 0< not
@           <>
@           if
@             1+
@             next
@             r> drop 0 dup, exit
@ Now we are going to scan for the next delimiter that will mark the end of
@  the word to parse.
@           else
@             r>            \ Remaining character count.
@           then
@         next
@       else
@         over              \ Pointer to first caracter of word to parse.
@         swap
@         for               \ Save count to be used in the loop.
@           tmp @           \ Separator
@           over c@         \ Next character of the word to parse.
@           -
@           tmp @ bl =      \ Scan for a blank
@           0<              \ Is the character to parse a valid letter?
@           if
@             1+            \ Add one to the parse pointer.
@             next
@           then
@         until
@         dup >r            \ Save end pointer to return stack.
@         over -            \ Calculate length of word parsed.
@         r> r> -           \ Calculate remaining characters to parse.
@       next
@     then
@   else
@     over r> -
@   then ;
                CODE        forth_link_address, 0, -parse, mparse
                m_varc      mparse_tmp_var
                m_store
                m_over
                m_tor
                m_dupp
                m_qbranc    mpars8
                m_oneminus
                m_varc      mparse_tmp_var
                m_at
                m_dolit     ' '
                m_equal
                m_qbranc    mpars3
                m_tor
mpars1:         m_dolit     ' '
                m_over
                m_cat
                m_minus
                m_zless
                m_not
                m_qbranc    mpars2
                m_oneplus
                m_nextc     mpars1
                m_rfrom
                m_drop
                m_dolit     0
                m_dupp
                m_next
mpars2:         m_rfrom
mpars3:         m_over
                m_swap
                m_tor
mpars4:         m_varc      mparse_tmp_var
                m_at
                m_over
                m_cat
                m_minus
                m_varc      mparse_tmp_var
                m_at
                m_dolit     ' '
                m_equal
                m_qbranc    mpars5
                m_zless
mpars5:         m_qbranc    mpars6
                m_oneplus
                m_nextc     mpars4
                m_dupp
                m_tor
                m_bran      mpars7
mpars6:         m_rfrom
                m_drop
                m_dupp
                m_oneplus
                m_tor
mpars7:         m_over
                m_minus
                m_rfrom
                m_rfrom
                m_minus
                m_next
mpars8:         m_over
                m_rfrom
                m_minus
                m_next
mparse_tmp_var: .word       tmp_var

@ parse ( c -- b u ; <string> )
@ Scan input stream and return counted string delimited by c.
@ Enters with:
@          c : Delimiter character.
@ Exits with:
@          b : Address of first byte of string to parse.
@          u : Length of the string.
@
@ : parse
@       >r                  \ Save the separator.
@       tib >in @ +         \ Reach the next word to parse in the buffer.
@       #tib @ >in @ -      \ Compute the number of remaining characters to
@                           \  parse.
@       >r -parse           \ Recover separator from return stack and parse.
@       >in +! ;            \ Update the count of parsed characters.
                COLON       forth_link_address, 0, parse, parse
                .word       tor
                .word       tib, inn, at, plus
                .word       ntib, at, inn, at, minus
                .word       rfrom
                .word       mparse
                .word       inn, pstor
                .word       exit

@ word ( -- a ; <string> )
@ Parse a word from input stream and copy it to name dictionary.
@
@ : word
@     parse               \ Parse the input text using TOS as the
@                         \  separator character.
@     (255 - MASKK) min   \ Limit to 31 characters the length of the word
@                         \  parsed (the other 3 bits are the lexicon ones).
@     here                \ Store the counted string in the vocabulary space.
@     pack$ ;             \ Pack the string.
                COLON       forth_link_address, 0, word, word
                .word       parse
                .word       dolit, (255 ^ MASKK), min
                .word       here
                .word       packs
                .word       exit

@ Interpret the input stream.
@
@ : eval ( -- )
@     begin
@       bl word         \ Get next token and pack it as a string.
@       dup c@
@     while             \ If the length is zero, exit.
@       'eval @execute  \ Execute command (default: $interpret).
@       ?stack          \ Abort if the data stack underflows.
@     repeat
@     drop
@     'tprompt @execute ; \ Print prompt.
                COLON       forth_link_address, 0, eval, eval
eval1:          .word       blank, word
                .word       dupp, cat
                .word       qbranch, eval2
                .word       teval
                .word       atexe
                .word       qstack
                .word       branch, eval1
eval2:          .word       drop, tprompt, atexe
                .word       exit

@ accept    ( b u -- b u )
@ Accept characters to input buffer. Return with actual count.
@ This is the function associated to the 'exepect vector upon bootup of the
@  system, and thus executed by the 'query' function.
@ Calls the funton pointed to by the 'tap (by default 'ktap') to process a
@  keystroke.
@
@ : accept
@     over + over       \ Calculate the address of the end of the buffer.
@     begin
@       2dup xor
@       if                \ If there is more room in the buffer collect more.
@         key             \ Wait for next key press.
@         dup             \ else exit with the maximum characters in the buffer.
@         ' ' '~' within
@         if
@           ktap          \ Process '\r'.
@         else
@           'tap @execute
@         then            \ Process regular characters.
@       again
@     else
@       drop              \ Drop address of last byte written
@       over -            \ Compute the length of the string in the TIB.
@     then ;
                COLON       forth_link_address, 0, accept, accept
                .word       over, plus, over
accp1:          .word       ddup, xorr
                .word       qbranch, accp4
                .word       key
                .word       dupp
                .word       dolit, ' ', dolit, '~' + 1, within
                .word       qbranch, accp2
                .word       tap
                .word       branch, accp3
accp2:          .word       ttap, atexe
accp3:          .word       branch, accp1
accp4:          .word       drop, over, minus, exit

@ query    ( -- )
@ Accept input stream to terminal input buffer. Calls the function pointed to
@  by the vector 'expect, which is, upon boot, set to 'accept'.
@
@ : query
@     tib MAX_LINE_CHARS
@     'expect @execute         \ Read up to 80 input characters into TIB.
@     #tib !                   \ Store the actual number of characters read
@                              \ in #tib.
@     drop                     \ Drop buffer address.
@     0 >in ! ;                \ Reset the pointer of the temp buffer.
                COLON       forth_link_address, 0, query, query
                .word       tib, dolit, MAX_LINE_CHARS
                .word       texpe, atexe
                .word       ntib, store
                .word       drop
                .word       dolit, 0, inn, store, exit

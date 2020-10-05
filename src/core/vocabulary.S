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

@ nfat> ( nfa -- cfa )
@ Return a code address given a name address.
@ Given that this is a direct threaded implementation there is no CFA per se.
@ We make the CFA point to the first executable instruction of the word, which
@  is either the assembly instructions for a CODE word or the ENTER instruction
@  for a COLON definition.
@
@ : nfa>cfa
@      dup c@           \ Read string length.
@      ~MASKK and       \ Mask off lexicon bits.
@      1+               \ Add one for the length byte itself.
@      +                \ Add to NFA.
@      aligned ;        \ Align to word boundary.
@                COLON       forth_link_address, 0, nfa>cfa, nfa2cfa
@                .word       dupp, cat
@                .word       dolit, ~MASKK, andd
@                .word       oneplus
@                .word       plus
@                .word       aligned
@                .word       exit
                CODE        forth_link_address, 0, nfa>cfa, nfa2cfa
                m_nfa2cfa
                m_next

@ : nfa>lfa ( nfa -- lfa)
@ Starts with a NFA and ends with a LFA.
@ : nfa>lfa
@     4- ;
                CODE        forth_link_address, 0, nfa>lfa, nfa2lfa
                m_fourminus
                m_next

@ : lfa>nfa ( nfa -- lfa)
@ Starts with a LFA and ends with a NFA.
@ : lfa>nfa
@     4+ ;
                CODE        forth_link_address, 0, lfa>nfa, lfa2nfa
                m_lfa2nfa
                m_next

@ : lfa>cfa ( nfa -- lfa)
@ Starts with a LFA and ends with a CFA.
@ : lfa>cfa
@     4+ nfa>cfa ;
                CODE        forth_link_address, 0, lfa>cfa, lfa2cfa
                m_lfa2cfa
                m_next

@ : cfa>nfa ( cfa -- nfa | 0 )
@ Starts with a CFA and ends with a NFA, or 0 for failure.
@
@ : cfa>nfa
@     context @             \ LFA of the transient dictionary.
@     dup >r                \ Save context vocabulary list.
@     @ @                   \ First LFA.
@     begin
@       over >r             \
@       lfa>cfa             \
@       r> <>               \ Compare CFAs
@     while
@       @ ?dup 0=           \ End of dictionary?
@       if
@         r> 4+             \ Fetch next dictionary pointer.
@         dup @ ?dup        \ Is it 0?
@         if
@           drop FALSE      \ Terminate word with a FALSE flag.
@         then
@           swap >r         \ Continue on.
@       then
@     repeat
@     nip                   \
@     lfa>nfa               \
@     r> drop               \ Remove dictionary pointer.
@     then
@   until ;
                CODE        forth_link_address, 0, cfa>nfa, cfa2nfa
                m_varc      cfa2nfa_context
                m_dupp
                m_tor
                m_at
                m_at
cfa2nfa1:       m_over
                m_tor
                m_dupp
                m_lfa2cfa
                m_rfrom
                m_nequal
                m_qbranc    cfa2nfa2
                m_at
                m_qdup
                m_zequ
                m_qbranc    cfa2nfa3
                m_rfrom
                m_fourplus
                m_dupp
                m_at
                m_qdup
                m_zequ
                m_qbranc    cfa2nfa4
                m_drop
                m_dolit     FALSE
                m_next
cfa2nfa4:       m_swap
                m_tor
cfa2nfa3:       m_bran      cfa2nfa1
cfa2nfa2:       m_nip
                m_fourplus
                m_rfrom
                m_drop
                m_next
cfa2nfa_context: .word      context_var

@ same? ( a1 a2 u -- a1 a2 f \ -0+ )
@ Compare u words (32 bits) in memory at addresses a1 and a2.
@ Return 0 if identical.
                CODE        forth_link_address, 0, ?same, sameq
                m_sameq
                m_next

@ (find) ( a da -- lfa -1|1 | a false )
@ Search a dictionary for a string. Return LFA and 1 if the IMMEDIATE lexcon
@  bit of the word is set, LFA and -1 if the IMMEDIATE lexicon bit of the word
@  is not set, LFA of the word to search and 0 if the word is not found in
@  the dictionary.
@ Enters with
@  'a' as the pointer to a counted string with the name to search
@  'da' as the pointer to a dictionary to search (i.e. the LFA of the word at
@        the tail of the dictionary list.)
@
@ : (find)
@   swap                \ va a
@   dup
@   c@                  \ Read string length.
@   1+                  \ Add length byte.
@   aligned             \ Round up to a 32 bit boundary.
@   4/                  \ Compute cell count needed to hold the string of
@                       \  character.
@   tmp !               \
@   dup @               \ Count byte and up to 3 characters of the name.
@   >r                  \
@   4+                  \ Move past first 3 bytes.
@   swap                \ TOS is now the dictionary pointer.
@   begin
@                       \ Even in an empty dictionary it is safe to enter this
@                       \  loop.
@       lfa>nfa         \ Reach the NFA.
@       dup @           \ Load length byte and first 3 characters of the
@                       \  word in the dictionary.
@       MASKK invert    \ ~MASKK
@       and             \ Ignore lexicon bits
@       r@              \ Compare length byte and first 3 charaters.
@       =
@       if
@         \ The length and up to 3 characters match. Compare the rest.
@         4+ tmp @ 1- same? \ Compare the next 4 characters of the name.
@                           \ If they are the same keep comparing without
@                           \  executing the while part.
@         0=
@         if
@           \ We found the word we were looking for.
@           r> drop             \ Clear the entry in R.
@           swap drop           \ Drop the pointer to the word to search.
@           4- 4-               \ Reach the LFA of the word we found.
@           dup 4+
@           swap
@           c@ IMMED and        \ IMMED bit is set?
@           TRUE swap
@           if
@             negate
@           then
@           exit
@         then
@       then
@         nfa>lfa
@         dup @             \ Read LFA of this word.
@       else
@   while
@   @                   \ Go back the the beginning of the counted string for
@   repeat              \
@   r> drop             \ Clear the entry in R.
@   drop                \ Drop the pointer to the word to search.
@   4-                  \ Reach the NFA of the word we found.
@   0 ;                 \ Word not found.
                CODE        forth_link_address, 0, (find), xfind
                m_swap
                m_dupp
                m_cat
                m_oneplus
                m_aligned
                m_fourslash
                m_varc      xfind_tmp_var
                m_store
                m_dupp
                m_at
                m_tor
                m_fourplus
                m_swap
xfind1:         m_lfa2nfa
                m_dupp
                m_at
                m_dolit     (0xFFFFFFFF ^ MASKK)    @ ~MASKK
                m_andd
                m_rat
                m_equal
                m_qbranc    xfind3
                m_fourplus
                m_varc      xfind_tmp_var
                m_at
                m_oneminus
                m_sameq
                m_zequ
                m_qbranc   xfind3
xfind5:         m_rfrom
                m_drop
                m_swap
                m_drop
                m_fourminus
                m_fourminus
                m_dupp
                m_fourplus
                m_cat
                m_dolit     IMMED
                m_andd
                m_dolit     TRUE
                m_swap
                m_qbranc    xfind7
                m_twocomp
xfind7:         m_next
xfind3:         m_fourminus
                m_at
                m_dupp
                m_qbranc    xfind2
                m_bran      xfind1
xfind2:         m_rfrom
                m_drop
                m_drop
                m_fourminus
                m_dolit     FALSE
                m_next
xfind_tmp_var:  .word       tmp_var

@ find    ( a -- ca -1 | 1 | a FALSE )
@ Search all context dictionaries for a string.
@ ANSI forth calls for an execution token to be returned by FIND. In this
@  implementation of FORTH going from an CFA to an NFA requires another
@  dictionary walk. To avoid this FIND returns an LFA, which does not require
@  a vocabulary search to find the NFA or CFA.
@
@: find
@    context dup >r \ Save a copy of the search list.
@    begin
@      @ @          \ LFA of first word in dictionary.
@      (find)       \ Scans a given dictionary.
@      dup 0=       \ If word is found exits the loop.
@    while
@      r> 4+        \ Read the pointer to the next dictionary to scan
@      dup          \
@      @ 0=         \ Is there any?
@      if
@        drop       \ Remove vocabulary pointer
@        exit
@      then
@        nip        \ Remove FALSE flag from (find).
@        dup >r     \ Store back dictionary pointer.
@      else
@    repeat
@    r> drop ;         \ Remove dictionary pointer
                COLON       forth_link_address, 0, find, find
                .word       context, dupp, tor
find1:          .word       at, at
                .word       xfind
                .word       dupp
                .word       zequ
                .word       qbranch, find2
                .word       rfrom, fourplus
                .word       dupp, at
                .word       zequ
                .word       qbranch, find3
                .word       drop
                .word       exit
find3:          .word       nip
                .word       dupp, tor
                .word       branch, find1
find2:          .word       rfrom, drop
                .word       exit

@ ?defined  ( a -- true | false )
                COLON       forth_link_address, 0, defined?, definedq
                .word       blank, word, find
                .word       nip, znequ, exit

@ This code does not appear as a vocabulary word and is otherwise inaccessible.
@ It is here to be able the reuse of a piece of code that is not otherwise
@  useful to a user.
                .equ        print_voc_name, . + 1
                ENTER
                .word       cr, dolit, 2, spaces
                .word       txtfgblue
                .word       count
                .word       dolit, ~MASKK, andd  @ Mask off lexicon bits.
                .word       types
                .word       txtnormal
                .word       exit

@ order ( -- )
@ Lists all context dictionaries plus the current dictionary.
@
@: order
@    ."| context"
@    context
@    begin
@      dup @
@      4+           \ Reach the pointer to the name of the context dictionary.
@      @            \ NFA of the name of the dictionary.
@      print_voc_name \
@      4+           \ Move on to next dictionary in context.
@      dup @ 0=     \ Last vocabulary in context?
@    until
@    drop           \ Drop the context pointer.
@    cr ."| current"
@    current @
@    4+             \ Reach the pointer to the name of the current dictionary.
@    print_voc_name ;
                COLON       forth_link_address, 0, order, order
                .word       cr
                .word       dotqp
                .byte       order_str1end - . - 1
                .ascii      "\x1b[1m\x1b[31mcontext\x1b[0m"
order_str1end:  .align      2, 0
                .word       context
order1:         .word       dupp, at, fourplus, at
                .word       print_voc_name
                .word       fourplus, dupp, at
                .word       zequ
                .word       qbranch, order1
                .word       drop
                .word       cr
                .word       dotqp
                .byte       order_str2end - . - 1
                .ascii      "\x1b[1m\x1b[31mcurrent\x1b[0m"
order_str2end:  .align      2, 0
                .word       current, at, fourplus, at
                .word       print_voc_name
                .word       exit

@ #vocs ( -- n)
@ Load the number of vocabularies in the search stack.
@
@ : #vocs
@   VOCSS ;
                CODE        forth_link_address, 0, #vocs, pvocs
                m_dolit     VOCSS
                m_next

@ definitions
@ Make the context vocabulary the current vocabulary.
@
@ : definitions
@   context @ current ! ;
                COLON       forth_link_address, 0, definitions, definitions
                .word       context, at
                .word       current, store
                .word       exit

@ seal
@ Remove all vocabularies except context from the search array
@
@ : seal ( -- )
@     context 4+        \ Start of area to clear, the resident dictionaries,
@                       \  just past the transient.
@      #vocs 4*         \ Number of bytes to clear.
@      erase ;
                COLON       forth_link_address, 0, seal, seal
                .word       context, fourplus
                .word       pvocs, fourstar
                .word       erase
                .word       exit

@ also
@ Push the context vocabulary onto the search array
@
@ : also ( -- )
@     context        \ Source address.
@     dup 4+         \ Destination address (resident dictionary pointers).
@     #vocs 1- 4*    \ Number of bytes to move.
@     cmove> ;       \ Move from high to low address.
                COLON       forth_link_address, 0, also, also
                .word       context, dupp
                .word       fourplus
                .word       pvocs, oneminus, fourstar
                .word       cmovet
                .word       exit

@ only
@ Makes forth the only dictionary in the search list.
@
@ : only ( -- )
@     root seal also ;
                COLON       forth_link_address, 0, only, only
                .word       forth
                .word       seal
                .word       also
                .word       exit

@ immediate    ( -- )
@ Make the last compiled word an immediate word.
@
@ : immediate
@     last @                    \ LFA of last word in dictionary.
@     lfa>nfa                   \ NFA of last worf in dictionary.
@     dup
@     c@                        \ Length byte.
@     IMMED or                  \ Set the IMMED bit.
@     swap c! ;                 \ Store back.
                .if         0
                COLON       forth_link_address, IMMED, immediate, immed
                __break__
                .word       last, at, lfa2nfa, dupp
                .word       cat, dolit, IMMED, orrr
                .word       swap, cstore, exit
                .else
                CODE        forth_link_address, IMMED, immediate, immed
                m_varconst  last_var
                m_at
                m_lfa2nfa
                m_dupp
                m_cat
                m_dolit     IMMED
                m_orrr
                m_swap
                m_cstore
                m_next
                .endif

@ [compile]    ( -- )
@ Compiles the next word even though it is flagged IMMEDIATE to execute
@  during compilation.
@
@ : [compile]
@     bl word find              \ Search for word.
@     0=
@     if                        \
@       throw                   \ If not found.
@     then
@     comma ;                   \ Store CFA.
                COLON       forth_link_address, IMMED, [compile], bcompile
                .word       blank, word, find
                .word       zequ
                .word       qbranch, bcompile1
                .word       throw
bcompile1:      .word       comma
                .word       exit

@ forget    ( -- )
@
@ : forget
@     context @ current @ -     \ Make sure context is current.
@     0=
@     if
@       bl word find            \ Search for word.
@       if
@         dup
@         fence @ u<            \ Compare with fence.
@         if
@           throw               \ If not found.
@         then
@         dup dp !              \ Store the new DP.
@         @                     \ LFA of word before the one to forget.
@         current @ ! ;         \ Store the new 'current'.
@       else
@         .id                   \ Pront the name of the offending word.
@         abort" "              \
@       then
@     else
@       abort" context is not current" \
@     then ;
                COLON       forth_link_address, 0, forget, forget
                .word       context, at
                .word       current, at, minus, zequ
                .word       qbranch, forget3
                .word       blank, word, find
                .word       qbranch, forget1
                .word       dupp, fence, at
                .word       uless
                .word       qbranch, forget2
                .word       throw
forget2:        .word       dupp, dp, store
                .word       at, current, at, store
                .word       exit
forget1:        .word       dotqp
                .byte       forget1_strend - . - 1
                .ascii      "\x1b[31m "
forget1_strend: .align      2, 0
                .word       dotid, dolit, 1
                .word       aborq
                .byte       forget2_strend - . - 1
                .ascii      ""
forget2_strend: .align      2, 0
                .word       exit
forget3:        .word       aborq
                .byte       forget3_strend - . - 1
                .ascii      "\x1b[31m context is not current\x1b[0m"
forget3_strend: .align      2, 0
                .word       exit

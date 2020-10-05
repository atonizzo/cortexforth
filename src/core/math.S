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

@ +    ( n1 n2 -- n1+n2 )
@ Add top two items.
                CODE        forth_link_address, 0, +, plus
                m_plus
                m_next

@ - ( n1 n2 -- n1-n2 )
@ Subtraction.
                CODE        forth_link_address, 0, -, minus
                m_minus
                m_next

@ 1+    ( n -- n+1 )
@ Add top two items.
                CODE        forth_link_address, 0, 1+, oneplus
                m_oneplus
                m_next

@ 1-    ( n -- n-1 )
@ Add top two items.
                CODE        forth_link_address, 0, 1-, oneminus
                m_oneminus
                m_next

@ 2+ ( n -- n+2 )
@ Add 2 to TOS.
                CODE        forth_link_address, 0, 2+, twoplus
                add         TOS, #2
                m_next

@ 2- ( n -- n-2 )
@ Subtract 2 from TOS.
                CODE        forth_link_address, 0, 2-, twominus
                add         TOS, #-2
                m_next

@ 4+ ( n -- n+4 )
@ Add 4 to TOS.
                CODE        forth_link_address, 0, 4+, fourplus
                m_fourplus
                m_next

@ 4- ( n -- n-4 )
@ Subtract 4 from TOS.
                CODE        forth_link_address, 0, 4-, fourminus
                m_fourminus
                m_next

@ um+ ( u u -- udsum )
@ Add two unsigned single numbers and return a double sum.
                CODE        forth_link_address, 0, um+, uplus
                m_uplus
                m_next

@ =        ( w w -- t )
@ Return true if top two are equal.
@ We need to create this header by hand, since = confuses the assembler.
                make_link   forth_link_address
                .byte       (ASMWR + 1)
                .ascii      "="
                .align      2, 0
                .equ        equal, . + 1
                m_equal
                m_next

@ <>       ( w w -- t )
@ Return true if top two are different.
                CODE        forth_link_address, 0, <>, nequal
                m_nequal
                m_next

@ < ( n1 n2 -- flag )
@ Signed compare of top two items.
@ Flag is true if and only if n1 is less than n2.
                CODE        forth_link_address, 0, <, lthan
                m_less
                m_next

@ > ( n1 n2 -- flag )
@ Signed compare of top two items.
@ Flag is true if and only if n1 is greater than n2.
                CODE        forth_link_address, 0, >, grthan
                m_grthan
                m_next

@ u< ( u1 u2 -- flag )
                CODE        forth_link_address, 0, u<, uless
                m_uless
                m_next

@ max ( n n -- n )
@ Return the greater of two top stack items.
                CODE        forth_link_address, 0, max, max
                m_max
                m_next

@ min ( n n -- n )
@ Return the smaller of top two stack items.
                CODE        forth_link_address, 0, min, min
                m_min
                m_next

@ s>d ( n -- d ) Sign extend a single into a double.
                CODE        forth_link_address, 0, s>d, stod
                m_stod
                m_next

@ within ( u ul uh -- t )
@ Return true if u is within the range of ul and uh. ( ul <= u < uh )
@ This is the definition of within that is recommended by Forth 2012.
@
@ : within
@      over - >r - r> u< ;
                CODE        forth_link_address, 0, within, within
                m_within
                m_next

@ negate    ( n -- -n )
@ Two's complement of TOS.
@
@ : negate not 1+ ;
                CODE        forth_link_address, 0, negate, twocomp
                m_twocomp
                m_next

@ dnegate ( d -- -d )
@ Two's complement of top double.
                CODE        forth_link_address, 0, dnegate, dnega
                m_dnegate
                m_next

@ abs ( n -- n )
@ Return the absolute value of n.
                CODE        forth_link_address, 0, abs, abss
                m_dupp
                m_zless
                m_qbranc    abs1
                m_twocomp
abs1:           m_next

@ ------------------------------------------------------------------------------
@                     L O G I C
@ ------------------------------------------------------------------------------
@ or ( w w -- w )
@ Bitwise OR.
                CODE        forth_link_address, 0, or, orrr
                m_orrr
                m_next

@ and ( w w -- w )
@ Bitwise AND.
                CODE        forth_link_address, 0, and, andd
                m_andd
                m_next

@ xor ( w w -- w )
@ Bitwise exclusive OR.
                CODE        forth_link_address, 0, xor, xorr
                m_xorr
                m_next

@ invert ( w -- w )
@ One's complement of TOS.
                CODE        forth_link_address, 0, invert, onecomp
                m_not
                m_next

@ lshift ( w u -- w )
@ Logical shift LEFT.
@ Perform a logical left shift of u bit-places on x1, giving x2.
                CODE        forth_link_address, 0, <<, lshift
                m_lshiftl
                m_next

@ rshift ( x1 u -- x2 )
@ Logical shift RIGHT.
@ Perform a logical right shift of u bit-places on x1, giving x2.
                CODE        forth_link_address, 0, >>, rshift
                m_lshiftr
                m_next

@ 0= ( n -- t )
@ Return true if n is 0.
                make_link   forth_link_address
                .byte       (ASMWR + 2)
                .ascii      "0="
                .align      2, 0
                .equ        zequ, . + 1
                m_zequ
                m_next

@ 0<> ( n -- t )
@ Return true if n is not 0.
                make_link   forth_link_address
                .byte       (ASMWR + 2)
                .ascii      "0<>"
                .align      2, 0
                .equ        znequ, . + 1
                m_znequ
                m_next

@ 0< ( n -- t )
@ Return true if n is negative.
                CODE        forth_link_address, 0, 0<, zless
                m_zless
                m_next

@ 0> ( n -- t )
@ Return true if n is greater than 0.
                CODE        forth_link_address, 0, 0>, zplus
                m_zplus
                m_next

@ ------------------------------------------------------------------------------
@                     M U L T I P L I C A T I O N
@ ------------------------------------------------------------------------------
@ um* ( u u -- ud )
@ Unsigned multiply. Return double product.
                CODE        forth_link_address, 0, um*, umsta
                m_umull
                m_next

@ *  ( n n -- n * n )
@ Signed multiply. Return single product.
                CODE        forth_link_address, 0, *, star
                m_star
                m_next

@ 2* ( n -- 2 * n )
@ Multiply by 2.
                CODE        forth_link_address, 0, 2*, twostar
                m_twostar
                m_next

@ 4* ( n -- 4 * n )
@ Multiply by 4.
                CODE        forth_link_address, 0, 4*, fourstar
                m_fourstar
                m_next

@ ------------------------------------------------------------------------------
@                     D I V I S I O N
@ ------------------------------------------------------------------------------
@ um/mod ( udl udh un -- ur uq )
@ Divide ud(h,l) by un, giving the quotient up and the remainder ur.
@ All values and arithmetic are unsigned. An ambiguous condition exists if
@ u1 is zero or if the quotient lies outside the range of a single-cell
@ unsigned integer.
@
@: um/mod ( ud u -- ur uq )
@  2dup u<                                \ Can we fit the result in 32 bits?
@  if
@    negate 31
@    for
@      >r dup um+ >r >r dup um+ r> + dup
@        r> r@ swap >r um+  r> or
@      if
@        >r drop 1 + r>
@      else
@        drop
@      then
@      r>
@    next
@    drop swap
@    exit
@  then
@  drop 2drop  -1 dup ;

                CODE        forth_link_address, 0, um/mod, ummod
                m_ummod
                m_next

@ m/mod ( d n -- r q )
@ Signed floored divide of double by single. Return mod and quotient.
                CODE        forth_link_address, 0, m/mod, msmod
                m_dupp
                m_zless
                m_dupp
                m_tor
                m_qbranc    msmod21
                m_twocomp
                m_tor
                m_dnegate
                m_rfrom
msmod21:        m_tor
                m_dupp
                m_zless
                m_qbranc    msmod22
                m_rat
                m_plus
msmod22:        m_rfrom
                m_ummod
                m_rfrom
                m_qbranc    msmod23
                m_swap
                m_twocomp
                m_swap
msmod23:        m_next

@ /mod ( n n -- r q )
@ Signed divide. Return mod and quotient.
@
@ : /mod
@     over 0<               \ Sign extend the dividend to make a double.
@     swap m/mod            \ Perform a double by single precision division.
@     exit
                COLON       forth_link_address, 0, /mod, slmod
                .word       over
                .word       zless
                .word       swap
                .word       msmod
                .word       exit

@ MOD ( n n -- r )
@ Signed divide. Return mod only.
@
                COLON       forth_link_address, 0, mod, mod
                .word       slmod, drop
                .word       exit

@ / ( n n -- q )
@ Signed divide. Return quotient only.
                CODE        forth_link_address, 0, /, slash
                m_slash
                m_next

@ 2/ ( n -- q )
@ Divide by 2.
                CODE        forth_link_address, 0, 2/, twoslash
                m_twoslash
                m_next

@ 4/ ( n -- q )
@ Divide by 4.
                CODE        forth_link_address, 0, 4/, fourslash
                m_fourslash
                m_next

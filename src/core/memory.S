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

@ ! ( w a -- )
@ Write a 32 bit value w to memory address a.
                CODE        forth_link_address, 0, !, store
                m_store
                m_next

@ 2! ( d2 d1 a -- )
@ Store the double integer to address a.
@ We end up with with [a] = d1 and [a + 4] = d2
                CODE        forth_link_address, 0, 2!, dstor
                m_dstor
                m_next

@ h! ( w h -- )
@ Write a 16 bit value to memory.
                CODE        forth_link_address, 0, h!, hstore
                m_hstore
                m_next

@ c! ( c b -- )
@ Write an 8 bit value to memory.
                CODE        forth_link_address, 0, c!, cstore
                m_cstore
                m_next

@ h@ ( a -- w )
@ Read content of memory location into the data stack (16 bits).
                CODE        forth_link_address, 0, h\@, hat
                m_hat
                m_next

@ @ ( a -- w )
@ Read content of memory location into the data stack.
                CODE        forth_link_address, 0, \@, at
                m_at
                m_next

@ c@ ( a -- c )
                CODE        forth_link_address, 0, c\@, cat
                m_cat
                m_next

@ Fetch double integer from address a.
@ When we enter with ADDR on TOS, the value on TOS at the end will
@  be [ADDR] then [ADDR + 4]
@
@ : 2@ ( a -- d )
@   dup CELLL + @           \ Fetch first word...
@   swap @ ;                \ ...then second.
                CODE        forth_link_address, 0, 2\@, dat
                m_dat
                m_next

@ @m! ( m1 m2 a -- )
@ Read-Modify-Write instruction. The contents of the 32 bit memory location
@  pointed to by a are ANDed with the one's complement of m1 (this will clear
@  all the bits set in m1) and ORed with m2 (this will set all the bits set in
@  m2.
                CODE        forth_link_address, 3, \@m!, rmw
                m_rmw
                m_next

@ +! ( n a -- )
@ Add n to the contents at address a.
                CODE        forth_link_address, 0, +!, pstor
                m_pstor
                m_next

@ cmove> ( src dest count -- )
@ Copy count bytes from src to dest from high to low addresses.
                CODE        forth_link_address, 0, cmove>, cmovet
                m_cmovet
                m_next

@ cmove ( src dest u -- )
@ Copy u bytes from b1 to b2.
                CODE        forth_link_address, 0, cmove, cmove
                m_cmove
                m_next

@ fill ( dest u c -- )
@ Fill u bytes starting at dest with character c.
                CODE        forth_link_address, 0, fill, fill
                m_fill
                m_next

@ erase ( addr u -- )
@ Fills u bytes of memory starting at address addr with 0.
@
@ : erase
@   0 fill ;
@
                CODE        forth_link_address, 0, erase, erase
                m_dolit     0
                m_fill
                m_next

@ allot    ( n -- )
@ Allocate n bytes to the code dictionary.
                COLON       forth_link_address, 0, allot, allot
                .word       dp, pstor, exit

@ ?  ( a -- )
@ Prints the contents of the memory location at a.
                COLON       forth_link_address, 0, ?, qmark
                .word       at, dot, exit

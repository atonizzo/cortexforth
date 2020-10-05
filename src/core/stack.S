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

@ @ dup ( w -- w w )
@ Duplicate the top stack item.
                CODE        forth_link_address, 0, dup, dupp
                m_dupp
                m_next

@ ?dup    ( w -- w w | 0 )
@ Dup tos if its not zero.
                CODE        forth_link_address, 0, ?dup, qdup
                m_qdup
                m_next

@ 2dup ( w1 w2 -- w1 w2 w1 w2 )
@ Duplicate top two items.
@
@ : 2dup over over ;
                CODE        forth_link_address, 0, 2dup, ddup
                m_ddup
                m_next

@ over ( w1 w2 -- w1 w2 w1 )
@ Copy second stack item to top.
                CODE        forth_link_address, 0, over, over
                m_over
                m_next

@ swap ( w -- w w )
@ Exchange top two stack items.
                CODE        forth_link_address, 0, swap, swap
                m_swap
                m_next

@ drop ( w -- )
@ Drop the TOS
                CODE        forth_link_address, 0, drop, drop
                m_drop
                m_next

@ 2drop ( w w -- )
@ Drop the top 2 values from the PSP.
                CODE        forth_link_address, 0, 2drop, ddrop
                m_ddrop
                m_next

@ pick ( ... +n -- ... w )
@ Copy the nth stack item to tos.
                CODE        forth_link_address, 0, pick, pick
                m_pick
                m_next

@ rot  ( w1 w2 w3 -- w2 w3 w1 )
@ Rotate the 3rd item to top.
                CODE        forth_link_address, 0, rot, rot
                m_rot
                m_next

@ nip ( x1 x2 -- x2 )
@
@ : nip swap drop ;
                CODE        forth_link_address, 0, nip, nip
                m_nip
                m_next

@ tuck ( w1 w2 -- w2 w1 w2 )
@
@ : tuck swap over ;
                CODE        forth_link_address, 0, tuck, tuck
                m_tuck
                m_next

@ rp@ ( -- a )
@ Push the current RP to the data stack.
@ We need to create this header by hand, since @ is the directive for comments
@  and that confuses the assembler.
                CODE        forth_link_address, COMPO, rp\@, rpat
                m_rpat
                m_next

@ sp! ( a -- )
@ Set the data stack pointer.
                CODE        forth_link_address, 0, sp!, spsto
                m_spsto
                m_next

@ rdrop ( -- )
@ Drops one item from the return stack.
                CODE        forth_link_address, 0, rdrop, rdrop
                m_rdrop
                m_next

@ rp! ( a -- )
@ Set the return stack pointer.
                CODE        forth_link_address, COMPO, rp!, rpsto
                m_rpsto
                m_next

@ sp@ ( -- a )
@ Push the current data stack pointer.
@ This operation is a bit tricky because the top of PSP is held in a register.
@ What we do is make a copy of the TOS in the PSP, and then return the
@  address of this copy.
                CODE        forth_link_address, 0, sp\@, spat
                m_spat
                m_next

@ r> ( -- w )
@ Pop the return stack to the data stack.
                CODE        forth_link_address, COMPO, r>, rfrom
                m_rfrom
                m_next

@ >r ( w -- )
@ Push the data stack to the return stack.
                CODE        forth_link_address, COMPO, >r, tor
                m_tor
                m_next

@ r@ ( a -- c )
@ Copy top of return stack to the data stack.
                CODE        forth_link_address, 0, r\@, rat
                m_rat
                m_next

@ 2r@ ( a -- c )
@ Copy top of return stack to the data stack.
@
                CODE        forth_link_address, 0, 2r\@, drat
                m_drat
                m_next

@ 2>r ( w1 w2 -- )
@ Transfer cell pair w1 w2 to the return stack
                CODE        forth_link_address, COMPO, 2>r, ttr
                m_ttr
                m_next

@ 2r> ( -- w )
@ Pop the return stack to the data stack.
                CODE        forth_link_address, COMPO, 2r>, drfrom
                m_drfrom
                m_next

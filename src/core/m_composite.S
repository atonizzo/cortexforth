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
@          M A C R O S   F O R   C O M P O S I T E   C O D E   W O R D S
@
@                       No assembler in this file!
@ All the words must be written using macros already defined in the m_forth.S
@ file.
@ ------------------------------------------------------------------------------
                .macro      m_ddrop
                m_drop
                m_drop
                .endm

                .macro      m_dnegate
                m_not
                m_tor
                m_not
                m_dolit     1
                m_uplus
                m_rfrom
                m_plus
                .endm

                .macro      m_within
                m_over
                m_minus
                m_tor
                m_minus
                m_rfrom
                m_uless
                .endm

                .macro      m_count
                m_dupp
                m_oneplus
                m_swap
                m_cat
                .endm

                .macro      m_aligned
                m_dolit     4
                m_swap
                m_align
                .endm

                .macro      m_drat
                m_rfrom
                m_rfrom
                m_over
                m_over
                m_tor
                m_tor
                m_swap
                .endm

                .macro      m_drfrom
                m_rfrom
                m_rfrom
                m_swap
                .endm

                .macro      m_ttr
                m_swap
                m_tor
                m_tor
                .endm

                .macro      m_twocomp
                m_not
                m_oneplus
                .endm

                .macro      m_ddup
                m_over
                m_over
                .endm

                .macro      m_ummod
                m_ddup
                m_uless
                m_qbranc    4f
                m_twocomp
                m_dolit     31
                m_forc
1:              m_tor
                m_dupp
                m_uplus
                m_tor
                m_tor
                m_dupp
                m_uplus
                m_rfrom
                m_plus
                m_dupp
                m_rfrom
                m_rat
                m_swap
                m_tor
                m_uplus
                m_rfrom
                m_orrr
                m_qbranc    2f
                m_tor
                m_drop
                m_oneplus
                m_rfrom
                m_bran      3f
2:              m_drop
3:              m_rfrom
                m_nextc     1b
                m_drop
                m_swap
                m_bran      5f
4:              m_drop
                m_ddrop
                m_dolit     0xFFFFFFFF
                m_dupp
5:
                .endm

                .macro      m_nfa2cfa
                m_dupp
                m_cat
                m_dolit     (0xFFFFFFFF ^ MASKK)    @ ~MASKK
                m_andd
                m_oneplus
                m_plus
                m_aligned
                .endm

                .macro      m_lfa2nfa
                m_fourplus
                .endm

                .macro      m_lfa2cfa
                m_lfa2nfa
                m_nfa2cfa
                .endm

@ types ( a u -- )
@ Prints u characters starting from pointer a.
@ : types
@       for
@           dup
@           c@      \ Read character.
@           emit
@           1+      \ Point to next character.
@       next
@       drop ;      \ Drop pointer.
                .if 1
                .macro      m_types
                m_forc
                m_bran      2f
1:              m_dupp
                m_cat
                m_emit
                m_oneplus
2:              m_nextc     1b
                m_drop
                .endm
                .else
@ TODO
@ Try to undertsand why this version of the code compiles the m_bran targets
@  differently for STM32F103 and STM32L476. With the values in the code the
@  m_branc and m_nextc seems to work for L476 devices but they are 2 bytes
@  short of the target for F103 devices.
                .macro      m_types
                m_forc
                m_bran      .+36        @ 2f
                m_dupp                  @ 1:
                m_cat
                m_emit
                m_oneplus
                m_nextc     .-46        @ 2: 1b
                m_drop
                .endm
                .endif

                .macro      m_for
                m_tor
                .endm

                .macro      m_upcase
                m_dupp
                m_dolit     'a'
                m_dolit     'z' + 1
                m_within
                m_qbranc    1f
                m_dolit     'a' - 'A'
                m_minus
1:
                .endm


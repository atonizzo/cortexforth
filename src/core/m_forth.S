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

                .macro      m_dolst
                PUSHH       IPP, RSP      @ Push IP into return stack.
@ We arrive here via ENTER implemented via a BLX instruction, which means that
@  the link register contains the new IP. Bit 0 of the LR is set (ARM Thumb bit)
@  and so we add 1 to it so that we end up on a word boundary. This assumes
@  that the 2 byte 'bx r8' instruction is itself on a word boundary.
                add         IPP, lr, #1
                .endm

                .macro      m_dolit value
                PUSHH       TOS, PSP
                .if         (\value & 0xFFFF0000) != 0
                movi32      TOS, \value
                .else
                mov         TOS, \value
                .endif
                .endm

                .macro      m_next
                NEXT
                .endm

                .macro      m_bran dest
                b           \dest
                .endm

                .macro      m_bkpt
                bkpt
                .endm

@ Version of ?branch to be used within colon definitions.
                .macro      m_qbran
                orrs        TOS, TOS
                POPP        TOS, PSP
                ite         eq
                ldreq       IPP, [IPP]
                addne       IPP, #4
                .endm

                .macro      m_execu
                orr         WREG1, TOS, #1  @ Set Thumb bit.
                POPP        TOS, PSP
                bx          WREG1
                .endm

                .macro      m_atexe
@                ldr         WREG1, [TOS]
@                POPP        TOS, PSP
@                orrs        WREG1, #1       @ Set Thumb bit.
@                it          ne
@                bxne        WREG1

                ldr         WREG1, [TOS]
                orrs        WREG1, WREG1
                POPP        TOS, PSP
                itt         ne
                orrne       WREG1, #1       @ Set Thumb bit.
                bxne        WREG1

                .endm

                .macro      m_dupp
                PUSHH       TOS, PSP
                .endm

                .macro      m_qdup
                cmp         TOS, #0
                it          ne
                strne       TOS, [PSP], #4
                .endm

                .macro      m_swap
                POPP        WREG1, PSP
                PUSHH       TOS, PSP
                mov         TOS, WREG1
                .endm

                .macro      m_rot
                PUSHH       TOS, RSP
                POPP        WREG1, PSP
                POPP        TOS, PSP
                PUSHH       WREG1, PSP
                POPP        WREG1, RSP
                PUSHH       WREG1, PSP
                .endm

                .macro      m_not
                eor         TOS, #-1
                .endm

                .macro      m_over
                PUSHH       TOS, PSP
                ldr         TOS, [PSP, #-8]
                .endm

                .macro      m_drop
                POPP        TOS, PSP
                .endm

                .macro      m_orrr
                POPP        WREG1, PSP
                orr         TOS, WREG1
                .endm

                .macro      m_andd
                POPP        WREG1, PSP
                and         TOS, WREG1
                .endm

                .macro      m_xorr
                POPP        WREG1, PSP
                eor         TOS, WREG1
                .endm

                .macro      m_zequ
                cmp         TOS, #0
                ite         ne
                movne       TOS, #FALSE
                moveq       TOS, #TRUE
                .endm

                .macro      m_znequ
                cmp         TOS, #0
                ite         ne
                movne       TOS, #TRUE
                moveq       TOS, #FALSE
                .endm

                .macro      m_emit
                .if         0
@ If you use this macro you must define a value at the end of the word that
@  looks like this:
@
@ local_temit_var: .word      temit_var
@
@ This way the temit execution vector will always be reachable.
                ldr         WREG1, local_temit_var
                ldr         WREG1, [WREG1]
                blx         WREG1
                .else
                m_uart_tx_char
                POPP        TOS, PSP
                .endif
                .endm

                .macro      m_zless
                orrs        TOS, TOS
                ite         lt
                movlt       TOS, TRUE    @ True.
                eorge       TOS, TOS     @ False.
                .endm

                .macro      m_zplus
                cmp         TOS, #0
                ite         ge
                movge       TOS, #TRUE
                movlt       TOS, #FALSE
                .endm

                .macro      m_less
                POPP        WREG1, PSP
                cmp         WREG1, TOS
                ite         ge
                movge       TOS, FALSE
                movlt       TOS, TRUE
                .endm

                .macro      m_grthan
                POPP        WREG1, PSP
                cmp         TOS, WREG1
                ite         ge
                movge       TOS, FALSE
                movlt       TOS, TRUE
                .endm

                .macro      m_uless
                POPP        WREG1, PSP
                cmp         WREG1, TOS
                .if         0
                mov         TOS, FALSE
                it          cc
                movcc       TOS, TRUE
                .else
                ite         cc
                movcc       TOS, TRUE
                movcs       TOS, FALSE
                .endif
                .endm

                .macro      m_store
                POPP        WREG1, PSP
                str         WREG1, [TOS]
                POPP        TOS, PSP
                .endm

                .macro      m_hstore
                POPP        WREG1, PSP
                strh        WREG1, [TOS]
                POPP        TOS, PSP
                .endm

                .macro      m_cstore
                POPP        WREG1, PSP
                strb        WREG1, [TOS]
                POPP        TOS, PSP
                .endm

                .macro      m_rmw
                PUSHH       TOS, RSP
                ldr         TOS, [TOS]
                POPP        WREG1, PSP
                POPP        WREG2, PSP
                bic         TOS, WREG2
                orr         TOS, WREG1
                POPP        WREG1, RSP
                str         TOS, [WREG1]
                POPP        TOS, PSP
                .endm

                .macro      m_rpat
                PUSHH       TOS, PSP
                mov         TOS, RSP
                .endm

                .macro      m_spsto
                mov         PSP, TOS
                eor         TOS, TOS
                .endm

                .macro      m_rpsto
                mov         RSP, TOS
                POPP        TOS, PSP
                .endm

                .macro      m_rdrop
                sub         RSP, #4
                .endm

                .macro      m_at
                ldr         TOS, [TOS]
                .endm

                .macro      m_hat
                ldrh        TOS, [TOS]
                .endm

                .macro      m_cat
                ldrb        TOS, [TOS]
                .endm

                .macro      m_spat
                PUSHH       TOS, PSP
                mov         TOS, PSP
                .endm

                .macro      m_rfrom
                PUSHH       TOS, PSP
                POPP        TOS, RSP
                .endm

                .macro      m_rat
                PUSHH       TOS, PSP
                ldr         TOS, [RSP, #-4]
                .endm

                .macro      m_pick
@ Notice the peculiar way in which this works even for a TOS that is held in a
@  register. The index of the word to pick is TOS, and thus all the stack
@  contents before the call to 'm pick' are now sitting in memory, where they
@  can be accessed with 'ldr TOS, [TOS, n]'.
@ In other words if we execute '0 pick' when pick is executed, 0 will be the
@  TOS but the value returned is the next value on the stack making '0 pick'
@  the equivalent of 'dup'.
                lsl         TOS, #2         @ 4 bytes per word.
                sub         TOS, PSP, TOS
                ldr         TOS, [TOS, #-4]
                .endm

                .macro      m_plus
                POPP        WREG1, PSP
                add         TOS, WREG1
                .endm

                .macro      m_uplus
                POPP        WREG1, PSP
                adds        WREG1, TOS
                eor         TOS, TOS
                adc         TOS, TOS
                PUSHH       WREG1, PSP
                .endm

                .macro      m_oneplus
                add         TOS, #1
                .endm

                .macro      m_oneminus
                sub         TOS, #1
                .endm

                .macro      m_minus
                POPP        WREG1, PSP
                sub         TOS, WREG1, TOS
                .endm

                .macro      m_fourplus
                add         TOS, #4
                .endm

                .macro      m_fourminus
                sub         TOS, #4
                .endm

                .macro      m_twostar
                lsl         TOS, #1
                .endm

                .macro      m_fourstar
                lsl         TOS, #2
                .endm

                .macro      m_twoslash
                asr         TOS, #1
                .endm

                .macro      m_fourslash
                asr         TOS, #2
                .endm

                .macro      m_star
                m_smull
                m_drop
                .endm

                .macro      m_stod
                PUSHH       TOS, PSP
                sbfx        TOS, TOS, #31, #1
                .endm

                .macro      m_nip
                sub         PSP, #4
                .endm

                .macro      m_tuck
                POPP        WREG1, PSP
                PUSHH       TOS, PSP
                PUSHH       WREG1, PSP
                .endm

                .macro      m_umull
                POPP        WREG1, PSP
                umull       WREG1, TOS, TOS, WREG1
                PUSHH       WREG1, PSP
                .endm

                .macro      m_smull
                POPP        WREG1, PSP
                smull       WREG1, TOS, TOS, WREG1
                PUSHH       WREG1, PSP
                .endm

                .macro      m_slash
                POPP        WREG1, PSP
                sdiv        WREG1, TOS
                mov         TOS, WREG1
                .endm

                .macro      m_tor
                PUSHH       TOS, RSP
                POPP        TOS, PSP
                .endm

                .macro      m_dstor
                POPP        WREG1, PSP
                str         WREG1, [TOS]
                POPP        WREG1, PSP
                str         WREG1, [TOS, #4]
                POPP        TOS, PSP
                .endm

                .macro      m_dat
                ldr         WREG1, [TOS, 4]
                PUSHH       WREG1, PSP
                ldr         TOS, [TOS]
                .endm

                .macro      m_equal
                POPP        WREG1, PSP
                cmp         TOS, WREG1
                ite         eq
                moveq       TOS, #TRUE
                movne       TOS, #FALSE
                .endm

                .macro      m_nequal
                POPP        WREG1, PSP
                cmp         TOS, WREG1
                ite         ne
                movne       TOS, #TRUE
                moveq       TOS, #FALSE
                .endm

                .macro      m_temit
                PUSHH       TOS, PSP
                ldr         TOS, 1f
                b           2f
1:              .word       temit_var
2:
                .endm

                .macro      m_pstor
                mov         WREG2, TOS
                ldr         TOS, [TOS]
                POPP        WREG1, PSP
                add         TOS, WREG1
                str         TOS, [WREG2]
                POPP        TOS, PSP
                .endm

                .macro      m_max
                POPP        WREG1, PSP
                cmp         WREG1, TOS
                it          pl
                movpl       TOS, WREG1
                .endm

                .macro      m_min
                POPP        WREG1, PSP
                cmp         TOS, WREG1
                it          pl
                movpl       TOS, WREG1
                .endm

@ Variables and constants are treated just the same. In the case of a variable
@  the 'value' is an address to which the variable value is stored.
                .if         0
                .macro      m_varconst, value
                PUSHH       TOS, PSP
                ldr         TOS, . + 8
                m_next
                .align      2, 0
                .word       \value
                .endm
                .else
                .macro      m_varconst, value
                PUSHH       TOS, PSP
                ldr         TOS, . + 4
                b           . + 6
                .word       \value
                .endm
                .endif

                .macro      m_align
                POPP        WREG1, PSP
                sub         WREG1, #1
                add         TOS, WREG1
                eor         WREG1, #-1
                and         TOS, WREG1
                .endm

                .macro      m_lshiftl
                POPP        WREG1, PSP
                lsl         TOS, WREG1, TOS
                .endm

                .macro      m_lshiftr
                POPP        WREG1, PSP
                lsr         TOS, WREG1, TOS
                .endm

                .macro      m_ashiftl
                POPP        WREG1, PSP
                asl         TOS, TOS, WREG1
                .endm

                .macro      m_ashiftr
                POPP        WREG1, PSP
                asr         TOS, TOS, WREG1
                .endm

@ Don't use labels such as "1:" here.
                .macro      m_cmove
                POPP        WREG2, PSP
                POPP        WREG1, PSP
                subs        TOS, #1
                itt         cs
                ldrbcs      WREG3, [WREG1], #1
                strbcs      WREG3, [WREG2], #1
                bcs         . - 12
                POPP        TOS, PSP
                .endm

                .macro      m_cmovet
                POPP        WREG2, PSP
                POPP        WREG1, PSP
                subs        TOS, #1
                itt         cs
                ldrbcs      WREG3, [WREG1, TOS]
                strbcs      WREG3, [WREG2, TOS]
                bcs         . - 8
                POPP        TOS, PSP
                .endm

                .macro      m_fill
                POPP        WREG1, PSP
                POPP        WREG2, PSP
                subs        WREG1, #1
                itt         cs
                strbcs      TOS, [WREG2, WREG1]
                bcs         . - 6
                POPP        TOS, PSP
                .endm

                .macro      m_donext
                POPP        WREG1, RSP
                subs        WREG1, #1
                itte        cs
                strcs       WREG1, [RSP], 4
                ldrcs       IPP, [IPP]
                addcc       IPP, 4
                .endm

                .macro      m_leave
                POPP        WREG1, RSP      @ Remove index count from RSP.
                POPP        WREG1, RSP      @ Remove limit.
                ldr         IPP, [IPP]
                .endm

                .macro      m_xdo
                POPP        WREG1, PSP
                PUSHH       WREG1, RSP
                PUSHH       TOS, RSP
                POPP        TOS, PSP
                .endm

                .macro      m_i
                m_rat
                .endm

@ ?do tests the limits. If they are the same, it skips past its matching 'loop'.
                .macro      m_xqdo dest
                POPP        WREG1, PSP
                cmp         TOS, WREG1
                ittte       ne
                strne       WREG1, [RSP], #4
                strne       TOS, [RSP], #4
                addne       IPP, #4
                ldreq       IPP, [IPP]
                POPP        TOS, PSP
                .endm

                .macro      m_xloop
                POPP        WREG1, RSP
                POPP        WREG2, RSP
                add         WREG1, #1
                cmp         WREG2, WREG1
                ittte       ne
                strne       WREG2, [RSP], #4
                strne       WREG1, [RSP], #4
                ldrne       IPP, [IPP]
                addeq       IPP, #4
                .endm

                .macro      m_xploop
                POPP        WREG1, RSP
                add         WREG1, TOS
                POPP        TOS, RSP
                cmp         TOS, WREG1
                ittte       ne
                strne       TOS, [RSP], #4
                strne       WREG1, [RSP], #4
                ldrne       IPP, [IPP]
                addeq       IPP, #4
                POPP        TOS, PSP
                .endm

                .macro      m_depth
                PUSHH       TOS, PSP
                ldr         WREG1, psp_reset_ptr2
                sub         TOS, R2, WREG1
                lsr         TOS, #2
                sub         TOS, #1
                .endm

@ This function is written in assembler because it can be used as a general
@  32 bit compare word.
                .macro      m_sameq
                .if 0
                cbz         TOS, . + 40
                sub         WREG3, TOS, #1
                POPP        WREG1, PSP
                POPP        WREG2, PSP
                ldr         TOS, [WREG1, WREG3]
                ldr         WREG4, [WREG2, WREG3]
                cmp         TOS, WREG4
                bne         . + 12
                sub         WREG3, #1
                bcc         . - 12
                eor         TOS, TOS
                PUSHH       WREG2, PSP
                PUSHH       WREG1, PSP
                .else
                cbz         TOS, . + 44
                push        {IPP}
                sub         WREG3, TOS, #1
                POPP        WREG1, PSP
                POPP        WREG2, PSP
                ldr         TOS, [WREG1, WREG3]
                ldr         IPP, [WREG2, WREG3]
                cmp         TOS, IPP
                bne         . + 12
                sub         WREG3, #1
                bcc         . - 12
                eor         TOS, TOS
                POP         {IPP}
                PUSHH       WREG2, PSP
                PUSHH       WREG1, PSP
                .endif
                .endm

@ These are special version of some words that must be used inside code words.
@ They work on a macro parameter instead of the next word in memory.
                .macro      m_qbranc dest
                orrs        TOS, TOS
                POPP        TOS, PSP
                beq         \dest
                .endm

                .macro      m_varc varname
                PUSHH       TOS, PSP
                ldr         TOS, \varname
                .endm

                .macro      m_qdo dest
                POPP        WREG1, PSP
                cmp         TOS, WREG1
                ittte       ne
                strne       WREG1, [RSP], 4
                strne       TOS, [RSP], 4
                ldrne       TOS, [PSP, #-4]
                ldreq       TOS, [PSP, #-4]
                bne         \dest
                .endm

                .macro      m_xqdoc dest
                POPP        WREG1, PSP
                PUSHH       WREG1, RSP
                PUSHH       TOS, RSP
                POPP        TOS, PSP
                b           \dest
                .endm

                .macro      m_forc
                m_tor
                .endm

                .macro      m_nextc dest
                POPP        WREG1, RSP
                subs        WREG1, #1
                itt         cs
                strcs       WREG1, [RSP], 4
                bcs         \dest
                .endm

                .macro      m_nextc2 dest
                POPP        WREG1, RSP
                subs        WREG1, #1
                itt         ne
                strne       WREG1, [RSP], 4
                bne         \dest
                .endm

                .macro      m_xloopc dest
                POPP        WREG1, RSP
                POPP        WREG2, RSP
                add         WREG1, #1
                cmp         WREG2, WREG1
                ittt        ne
                strne       WREG2, [RSP], #4
                strne       WREG1, [RSP], #4
                bne         \dest
                .endm

                .macro      m_xploopc dest
                POPP        WREG1, RSP
                POPP        WREG2, RSP
                add         WREG1, TOS
                POPP        TOS, PSP
                cmp         WREG1, WREG2
                ittt        lt
                strlt       WREG2, [RSP], #4
                strlt       WREG1, [RSP], #4
                blt         \dest
                .endm

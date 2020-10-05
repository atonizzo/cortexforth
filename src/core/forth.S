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
@                         C O R T E X F O R T H
@       An implementation of Forth for Cortex-M3 and Cortex-M4 cores.
@
@                          Anthony Tonizzo
@                        atonizzo@gmail.com
@                             2015-2020
@ ------------------------------------------------------------------------------
                .equ        ROM_VERSION, 1
                .equ        COMPILE_EDITOR, 0
                .equ        bsp, __BSP__

                .syntax     unified
                .global     start_forth
                .global     start_forth_2
                .thumb
                .type       start_forth, %function
                .type       __nmi_fault, %function
                .type       __hard_fault, %function
                .type       __mpu_fault, %function
                .type       __bus_fault, %function
                .type       __usage_fault, %function

                .section    .vectors
                .org        0
system_reset:   .long       core_stack
reset:          .long       start_forth
nmi_fault:      .long       __nmi_fault
hard_fault:     .long       __hard_fault
mpu_fault:      .long       __mpu_fault
bus_fault:      .long       __bus_fault
usage_fault:    .long       __usage_fault
                .long       0
                .long       0
                .long       0
                .long       0

__nmi_fault:    nop
1:              bkpt
                b           1b
__hard_fault:   nop
1:              bkpt
                b           1b
__mpu_fault:    nop
1:              bkpt
                b           1b
__bus_fault:    nop
1:              bkpt
                b           1b
__usage_fault:  nop
1:              bkpt
                b           1b

                .include    "src/core/m_forth.S"
                .include    "src/core/m_composite.S"
@ Version control
                .equ        VER, 0  @ Major release version.
                .equ        EXT, 8  @ Minor extension.

                .equ        CORE_STACK_SIZE, 32 * 4
                .equ        PSP_STACK_SIZE, 32 * 4
                .equ        RSP_STACK_SIZE, 32 * 4
                .equ        TIBB_STACK_SIZE, 64
                .equ        PAD_OFFSET, 512

                .equ        FALSE, 0            @ False flag.
                .equ        TRUE,  0xFFFFFFFF   @ True flag.
                .equ        ESC,   27           @ Escape character.
                .equ        ASM_DOLST, 0x47C0   @ Assembly encoding of 'bx r8'.
                .equ        MAX_LINE_CHARS, 80  @ Maximum number of characters
                                                @  in a single input line.

@ Constants for the screen editors.
                .equ        CHARACTERS_PER_LINE, 64
                .equ        ROWS_PER_BUFFER, 16
                .equ        RAM_BUFFER_SIZE, (CHARACTERS_PER_LINE * ROWS_PER_BUFFER + 4)

@ Register usage:
@
@ R0: Top of stack.
@ R1: Instruction Pointer
@ R2: Parameter Stack pointer
@ R3: Returns stack pointer
@ R8: Address of doList (for BL instruction).

@ {R0..R3, R12} are automatically saved during exceptions, so they are
@  assigned to state functions that need to be saved.
@ Exceptions will still be required to save the WREGs and any other register
@  they use.
TOS             .req        R0  @ Top of parameter stack.
IPP             .req        R1  @ Instruction Pointer.
PSP             .req        R2  @ Parameter Stack Pointer.
RSP             .req        R3  @ Return Stack Pointer.
WREG1           .req        R4  @ Working register.
WREG2           .req        R5  @ Working register.
WREG3           .req        R6  @ Working register.
WREG4           .req        R7  @ Working register.

@ The dolst address is constant even while executing exceptions, so it does
@  not need to be in the list of those saved on the stack.
DOLST_ADDR      .req        R8  @ Address of doList (for BLX instruction).

                .equ        ASMWR, 0x20 @ Word is in CODE.
                .equ        COMPO, 0x40 @ Word is compile only.
                .equ        IMMED, 0x80 @ Word is immediate.
                .equ        MASKK, (IMMED | COMPO | ASMWR) @ Lexicon bit mask.

                .equ        WORDS_PER_LINE, 5  @ Number of words per line in
                                               @  the 'words' output.

@ Maximum number of vocabularies in our search list.
                .equ        VOCSS, 8

@ Stacks are post-increment/pre-decrement. This makes the stack
@ pointer to point to the first useful value on the stack.
                .macro      PUSHH, what, from_where
                str         \what, [\from_where], 4
                .endm

                .macro      POPP, what, from_where
                ldr         \what, [\from_where, #-4]!
                .endm

                .macro      movi32 reg, val
                movw        \reg, #(\val & 0xFFFF)
                movt        \reg, #(\val >> 16)
                .endm

@ Dictionary structure.
@
@ |----------------------------------------------------------------------------|
@ | LFA (4 bytes)                                                              |
@ | The LFA points to the NFA of the previous word. 0 for the last word of a   |
@ | dictionary.                                                                |
@ |----------------------------------------------------------------------------|
@ | NFA                                                                        |
@ | The NFA is made up of a LENGTH byte followed by the ASCII characters of    |
@ | the name. If the length of the name plus the length byte is not on a 32    |
@ | bit boundary the name string is padded with 0.                             |
@ |----------------------------------------------------------------------------|
@ | CFA                                                                        |
@ | The CFA always points to executable assembly instructions.                 |
@ | If this is a code definition this is where the assembly instructions will  |
@ | be found. If this is a colon definition this is the code for ENTER is.     |
@ |----------------------------------------------------------------------------|
@ | PFA                                                                        |
@ | The PFA always points to start of the executable tokens of a given word    |
@ | and is it does not exist for a code word. All execution tokens all bit 0   |
@ | set, a condition required by the Cortex-M3 assembly instruction used to    |
@ | implement NEXT.                                                            |
@ |----------------------------------------------------------------------------|
@
                .macro      ENTER
                blx         DOLST_ADDR
@ This is a 2 bytes instruction. We align the PC to a word boundary so that the
@  pointer to Forth words will also be on a word boundary.
                .hword      0
                .endm

                .macro      NEXT
                ldr         pc, [IPP], #4
                .endm

                .macro      make_link dict
                .align      2, 0
                .word       \dict
                .set        \dict, . - 4    @ The LFA points to the LFA of
                                            @  the previous word.
                .endm

                .macro      CODE dict, lex, name, label
                make_link   \dict
                .byte       (ASMWR | \lex | ((1f - . - 1) & (255 - MASKK)))
                .ascii      "\name"
1:              .align      2, 0
@ The inner interpreter is "ldr pc, [ipp], #4" and in this case bit0 of the
@  destination must be set on all word addresses per Thumb2 instruction set.
@ The following addition of 1 accomplishes that.
                .equ        \label, . + 1
                .endm

                .macro      COLON dict, lex, name, label
                make_link   \dict
                .byte       (\lex | ((1f - . - 1) & (255 - MASKK)))
                .ascii      "\name"
1:              .align      2, 0
@ The inner interpreter is "ldr pc, [ipp], #4" and in this case bit0 of the
@  destination must be set on all word addresses per Thumb2 instruction set.
@ The following addition of 1 accomplishes that.
                .equ        \label, . + 1
                ENTER
                .endm

                .macro      VARIABLE dict, lex, name, label, var
                CODE        \dict, \lex, \name, \label
                m_varconst  \var
                m_next
                .endm

                .macro      CONSTANT dict, lex, name, label, value
                make_link   \dict
                .byte       (ASMWR | \lex | ((1f - . - 1) & (255 - MASKK)))
                .ascii      "\name"
1:              .align      2, 0
                .equ        \label, . + 1
                m_varconst  \value
                m_next
                .endm

                .macro      __break__
                .word       breakpoint
                .endm

                .macro      setbits addr, bitmask
                .word       dolit, \addr, at
                .word       dolit, \bitmask, orrr
                .word       dolit, \addr, store
                .endm

                .macro      clearbits addr, bitmask
                .word       dolit, \addr, at,
                .word       dolit, \bitmask, onecomp, andd
                .word       dolit, \addr, store
                .endm

                .set        editor_link_address, 0
                .set        forth_link_address, 0

                .data
                .org        0
@ram_start:
@ Core stack pointer used to save state/registers during subroutine calls and
@  exceptions.
core_stack_start: .space    CORE_STACK_SIZE - 4
core_stack:     .word       0
psp:            .space      PSP_STACK_SIZE
rsp:            .space      RSP_STACK_SIZE
tibb:           .space      TIBB_STACK_SIZE

@ram_variables_start:
tqkey_var:      .word       qrx            @ '?key
temit_var:      .word       txsto          @ 'emit
texpect_var:    .word       accept         @ 'expect
ttap_var:       .word       ktap           @ 'tap
techo_var:      .word       txsto          @ 'echo
tprompt_var:    .word       dotok          @ 'prompt
tboot_var:      .word       howdy          @ 'boot
base_var:       .word       10             @ base
tmp_var:        .word       0              @ tmp
span_var:       .word       0              @ span
inn_var:        .word       0              @ >in
ntib_var:       .word       0              @ #tib
                .word       tibb           @ tib
csp_var:        .word       0              @ csp
teval_var:      .word       inter          @ 'eval
tnumber_var:    .word       numbq          @ 'number
hld_var:        .word       0              @ hld
handler_var:    .word       0              @ handler

@ The transient and resident dictionary pointers point to the body of the
@  given 'dovoc' word.
context_var:    .word       forth_dict     @ context pointer (the transient
                                           @  vocabulary).
                .space      VOCSS * 4, 0   @ vocabulary stack (the resident
                                           @  vocabularies).
current_var:    .word       forth_dict     @ current pointer, where new words
                                           @  are added.
clobber_var:    .word       0              @ cp
padchar_var:    .word       '0'            @ Character to be used for padding
                                           @  the printout of numbers.
dtop_var:       .word       user_ram_start @ dp
fence_var:      .word       forth_word_lfa @ fence
last_var:       .word       forth_word_lfa @ last

@ Variables for the screen editor.
row_var:        .word       0
col_var:        .word       0
tabconst_var:   .word       0
islashr_var:    .word       0
scr_var:        .word       0

@ Variables for file IO.
prev_var:       .word       0
use_var:        .word       0
diskerror_var:  .word       0
var_var:        .word       0

@ Dictionaries defined in FLASH.
@ Each dictionary must have 2 words defined in RAM.
@ - The first is a pointer to the tail of the dictionary itself. The contents
@    of this location will change as more words are added to thie dictionary.
@ - The second is a pointer to the NFA of the name of the dictionary. The
@    contents pointed by this address never change.
forth_dict:     .word       last_forth_lfa
forth_dict_lfa: .word       forth_word_lfa + 4
                .if         COMPILE_EDITOR == 1
editor_dict:    .word       last_editor_lfa
editor_dict_lfa:.word       editor_word_lfa + 4

@ The following is an array containing the attribute words for each of the RAM
@ block buffers. The attributes are:
@ 0..15  : Block number
@ 16..31 : Attribute bits
buffer_attributes_var:
                .space      MAX_RAM_BUFFERS * 4, 0xFF
                .endif

@ LASTN points to the LFA of the last word of the Forth dictionary.
@                .set        forth_lfa_ptr, forth_link_address

                .align      2, 0
user_ram_start:

ram_cmove_end:

@ ------------------------------------------------------------------------------
@                          . T E X T
@ ------------------------------------------------------------------------------
                .text
start_forth_2:
start_forth:    ldr         r0, __system_reset
                ldr         r0, [r0]
                mov         sp, r0
                ldr         PSP, psp_reset_ptr
                ldr         RSP, rsp_reset_ptr
                ldr         DOLST_ADDR, dolst_ptr
                ldr         IPP, cold1_ptr
                eors        TOS, TOS
                NEXT

__system_reset: .word       system_reset

@ The core stack grows downwards so we give it the  address of the top of
@  its range.
dolst_ptr:      .word       dolist
psp_reset_ptr:  .word       psp
rsp_reset_ptr:  .word       rsp
cold1_ptr:      .word       cold1

@ ------------------------------------------------------------------------------
@                  I N N E R   I N T E R P R E T E R
@ ------------------------------------------------------------------------------
@ dolist ( -- )
@ Process colon list.
                CODE        forth_link_address, COMPO, dolist, dolist
                m_dolst
                m_next

@ exit    ( -- )
@ Terminate a colon definition.
                CODE        forth_link_address, COMPO, exit, exit
                POPP        IPP, RSP
                m_next

@ dolit ( -- w )
@ Push an inline literal.
                CODE        forth_link_address, COMPO, dolit, dolit
                PUSHH       TOS, PSP
                ldr         TOS, [IPP], #4 @ Get the next TOS from the IP.
                NEXT

@ breakpoint ( -- )
@ Push an inline literal.
                CODE        forth_link_address, 0, breakpoint, breakpoint
break_point:    nop
                NEXT

@ branch    ( -- )
@ Branch to an inline address.
                CODE        forth_link_address, COMPO, branch, branch
                ldr         IPP, [IPP]
                NEXT

@ ?branch ( f -- )
@ Branch if flag is zero.
                CODE        forth_link_address, COMPO, ?branch, qbranch
                m_qbran
                m_next

@ execute ( ca -- )
@ Execute the word at ca.
                CODE        forth_link_address, 0, execute, execute
                m_execu

@ @execute ( a -- )
@ Execute vector stored in address a.
                CODE        forth_link_address, 0, \@execute, atexe
                m_atexe
                m_next

@ align ( b a -- a )
@ Align number a to a b boundary.
                CODE        forth_link_address, 0, align, align
                m_align
                m_next

@ aligned ( b -- a )
@ Align address to the cell boundary.
                CODE        forth_link_address, 0, aligned, aligned
                m_aligned
                m_next

                .include    "src/core/stack.S"
                .include    "src/core/memory.S"
                .include    "src/core/math.S"

@ true ( -- TRUE )
@ Load a TRUE value.
                COLON       forth_link_address, 0, true, true
                .word       dolit, TRUE
                .word       exit

@ false ( -- FALSE )
@ Load a TRUE value.
                COLON       forth_link_address, 0, false, false
                .word       dolit, FALSE
                .word       exit

@ depth ( -- n )
@ Return the depth of the data stack.
                CODE        forth_link_address, 0, depth, depth
                m_depth
                m_next
psp_reset_ptr2: .word       psp

@ rdepth ( -- n )
@ Return the depth of the retun stack.
                CODE        forth_link_address, 0, rdepth, rdepth
                PUSHH       TOS, PSP
                ldr         WREG1, 1f
                sub         TOS, R3, WREG1
                lsr         TOS, 2
                m_next
1:              .word       rsp

@ tib ( -- a )
@ Return the address of the terminal input buffer.
@
@ : tib
@     #tib 4+ @ ;           \ tib is held in the word following #tib. It does
@                           \  not have its own address, so we get at it through
@                           \  #tib.
                COLON       forth_link_address, 0, tib, tib
                .word       ntib, fourplus, at, exit

@ dovoc ( -- )
@ Run time action of VOCABULARY's.
@
@ : dovoc
@    r> @ context ! ;
                COLON       forth_link_address, COMPO, dovoc, dovoc
                .word       rfrom, at, context, store, exit

@ here ( -- a )
@ Return the top of the code dictionary.
@
@ : here
@     dp @ ;
                COLON       forth_link_address, 0, here, here
                .word       dp, at, exit

@ pad ( -- a )
@ Return the address of a transient buffer above the code dictionary.
@
@ : pad
@     here PAD_OFFSET + ;
                COLON       forth_link_address, 0, pad, pad
                .word       here, dolit, PAD_OFFSET, plus, exit

@ hold ( c -- )
@ Insert a character into the numeric output string.
@
@ : hold
@     hld @ 1-            \ Point to the next character to store.
@     dup hld !           \ Store new pointer.
@     cstore ;            \ Store character.
                COLON       forth_link_address, 0, hold, hold
                .word       hld, at, oneminus
                .word       dupp, hld, store, cstore, exit

@ sign ( n -- )
@ Add a minus sign to the numeric output string.
@
@ : sign
@     0<     -            \ Less than 0?
@     if
@       '-' hold
@     then ;
                COLON       forth_link_address, 0, sign, sign
                .word       zless
                .word       qbranch, 1f
                .word       dolit, '-', hold
1:              .word       exit

@ str ( w -- b u )
@ Convert a signed integer to a numeric string.
@
@ : str
@     dup >r
@     abs
@     <# #s
@     r> sign
@     #> ;
                COLON       forth_link_address, 0, str, str
                .word       dupp, tor, abss
                .word       bdigs, digs, rfrom
                .word       sign, edigs, exit

@ decimal ( -- )
@ Use radix 10 as base for numeric conversions.
@
@ : decimal
@     10 base ! ;
                COLON       forth_link_address, 0, decimal, decimal
                .word       dolit, 10, base, store, exit

@ hex ( -- )
@ Use radix 16 as base for numeric conversions.
@
@ : hex
@     16 base ! ;
                COLON       forth_link_address, 0, hex, hex
                .word       dolit, 16, base, store, exit

@ ( ( -- )
@ Ignore following string up to next ) . A comment.
                COLON       forth_link_address, 0, \(, paren
                .word       dolit, ')', parse, ddrop, exit

@ \ ( -- )
@ Ignore following text till the end of line.
                COLON       forth_link_address, 0, \\, bksla
                .word       ntib, at, inn, store, exit

@ upcase ( c -- c )
@ Convert a character in the range of 'a' to 'z' to its uppercase equivalent.
@
@ : upcase
@     dup
@     'a' '{' within
@     if
@       'a' - 'A' -
@     then ;
                .if         0
                COLON       forth_link_address, 0, upcase, upcase
                .word       dupp
                .word       dolit, 'a', dolit, 'z' + 1, within
                .word       qbranch, upcase1
                .word       dolit, 'a' - 'A', minus
upcase1:        .word       exit
                .else
                CODE        forth_link_address, 0, upcase, upcase
                m_upcase
                m_next
                .endif

                .include    "src/core/name_compiler.S"

@ tap ( bot eot cur c -- bot eot cur )
@ Accept and echo the key stroke and bump the cursor.
@
@ : tap
@     dup 'echo @execute  \ Echo the character out to the terminal.
@     over c!             \ Store the character in the TIB.
@     1 + ;               \ Increment the TIB pointer.
                COLON       forth_link_address, 0, tap, tap
                .word       dupp, techo, atexe
                .word       over, cstore, oneplus, exit

@ nuf? ( -- t )
@ Return false if no input, else return true if CR.
@
@ : nuf?
@    ?key dup
@    if
@       drop                \ Drop flag from ?key.
@       CR =
@    then ;
                COLON       forth_link_address, 0, nuf?, nufq
                .word       qkey, dupp
                .word       qbranch, 1f
                .word       drop, dolit, cr, equal
1:              .word       exit

@ count ( b -- b +n )
@ Return count byte of a string and add 1 to byte address.
@
@ : count
@    dup
@    1+                     \ Pointer to the first character of the string.
@    swap c@ ;              \ Read the byte count.
                CODE        forth_link_address, 0, count, count
                m_count
                m_next

@ : do$ ( --- a )
@     r>            \ This is the address to the start of the string that
@                   \  must follow 'dotqp'.
@     dup           \
@     count         \ Calculate the length of the string.
@     +             \ Add that to the string pointer to get the address of the
@                   \  last byte of the string.
@     aligned       \ Align to a cell boundary to find the addres of the next
@                   \  instruction after the string.
@     >r ;          \ Store back to RSP.
                CODE        forth_link_address, COMPO, do$, dostr
                m_rfrom
                m_dupp
                m_count
                m_plus
                m_aligned
                m_tor
                m_next

@ $"|        ( -- a )
@ Run time routine compiled by $". Return address of a compiled string.
                make_link   forth_link_address
                .byte       COMPO + 3
                .ascii      "$\"|"
                .align      2, 0
                .equ        strqp, . + 1
                ENTER
                .word       dostr, exit

@ .r ( n +n -- )
@ Display an integer in a field of n columns, right justified.
                COLON       forth_link_address, 0, .r, dotr
                .word       tor, str, rfrom, over, minus
                .word       spaces, types, exit

@ $,"        ( -- )
@ Compile a literal string up to next " .
@
@ : $,"
@     '"' word      \ Delimit the string.
@     count         \ Length of string.
@     plus          \ Add to pointer
@     1+            \ Include length byte.
@     aligned       \ Align to word boundary.
@     dp ! ;        \
@
                make_link   forth_link_address
                .byte       COMPO + 3
                .ascii      "$,\""
                .align      2, 0
                .equ        strcq, . + 1
                ENTER
                .word       dolit, '"'
                .word       word
                .word       count, plus, aligned
                .word       dp, store
                .word       exit

@ ."| ( -- )
@ Run time routine of ." . Output a compiled string.
@ We need to create this header by hand, since '.' is the start of directive
@  commands and that confuses the assembler.
@
@ : ."|
@     do$           \ Address of compiled string.
@     count         \ Length.
@     type ;        \ Emit the characters.
                make_link   forth_link_address
                .byte       COMPO + 3
                .ascii      ".\"|"
                .align      2, 0
                .equ        dotqp, . + 1
                ENTER
                .word       dostr
                .word       count
                .word       types
                .word       exit

@ ." ( -- )
@ Compile time word for ."|.
@
                make_link   forth_link_address
                .byte       IMMED + 2
                .ascii      ".\""
                .align      2, 0
                .equ        dotq, . + 1
                ENTER
                .word       compile, dotqp
                .word       strcq
                .word       exit

@ u.r ( u +n -- )
@ Display an unsigned integer in n column, right justified.
@
@ : u.r
@    >r
@    <# #s #>       \ Turn the number into characters.
@    r> over -      \ Calculate how many spaces to type based on the
@                   \  justification requested and the length of the converted
@                   \  string.
@    padchar @      \ Padding character.
@    swap           \
@    chnemit        \
@    type ;
                COLON       forth_link_address, 0, u.r, udotr
                .word       tor, bdigs
                .word       digs, edigs
                .word       rfrom, over, minus
                .word       padchar, at
                .word       swap, chnemit
                .word       types
                .word       exit

@ u.        ( u -- )
@ Display an unsigned integer in free format.
@
@ : u.
@       <# #s #>       \ Turn the number into characters.
@       space          \
@       types ;        \ Print the number with a leading separator.
                COLON       forth_link_address, 0, u., udot
                .word       bdigs, digs, edigs
                .word       types, exit

@ . ( w -- )
@ Display an integer in free format.
@
@ : .
@     base @ 10 xor
@     if
@       udot            \ Non-decimal.
@     else
@       str types
@     then;
                COLON       forth_link_address, 0, ., dot
                .word       base, at, dolit, 10, xorr
                .word       qbranch, 1f
                .word       udot, exit
1:              .word       str, types, exit

@ ? ( a -- )
@ Display the contents of a 32 bit memory location.
                COLON       forth_link_address, 0, ?, qm
                .word       at, dot, exit

@ .id ( na -- )
@ Display the name at address.
@
@ : .id
@   ?dup
@   if
@     count           \ Get string length and pointer to the first
@                     \  character of the string.
@     ~MASKK and      \ Mask off lexicon bits.
@     _type           \ Print name.
@   else
@     ."| {noName}"   \
@   then ;
                COLON       forth_link_address, 0, .id, dotid
                .word       qdup
                .word       qbranch, dotid1
                .word       count
                .word       dolit, ~MASKK, andd
                .word       utype
                .word       exit
dotid1:         .word       dotqp
                .byte       dotid_strend - . - 1
                .ascii      " {noName}"
dotid_strend:   .align      2, 0
                .word       exit

@ dm+ ( a u -- a )
@ Dump u bytes from a, leaving a+u on the stack. u is rounded up to a multiple
@   of 16.
@
@ : dm+
@     base @ r>          \
@     hex                \
@     16 swap align      \ Print a multiple of 16 bytes.
@     over + swap        \ Create 'do' loop indexes.
@     do
@       i                \ Read pointer.
@       '$' emit         \ Type a '$' sign for a hex number.
@       i 8 u.r          \ Print the address in 8 colums.
@       16
@       for
@         space          \ Print space separator.
@         dup c@ 2 u.r   \ Print byte in 3 columns.
@         1+             \ Increment address.
@       next
@       16
@     +loop
@     1-                 \ a + u left on the stack.
@     r> base ! ;        \ Restore base.
                COLON       forth_link_address, 0, dm+, dumpp
                .word       base, at, tor, hex
                .word       dolit, 16, swap, align
                .word       over, plus, swap
                .word       xdo
                .word       index
2:              .word       dolit, '$', emit
                .word       index, dolit, 8, udotr
                .word       dolit, 16, tor
1:              .word       space
                .word       dupp, cat, dolit, 2, udotr
                .word       oneplus
                .word       xnext, 1b
                .word       dolit, 16
                .word       xploop, 2b
                .word       oneminus
                .word       rfrom, base, store
                .word       exit

@ dmw+ ( a u -- a )
@ Dump u words from a in 32 bit values, leaving a+u on the stack. u is rounded
@  up to a multiple of 16.
@
@ : dmw+
@     base @ r>         \
@     hex               \
@     16 swap align     \ Print a multiple of 16 bytes.
@     over + swap       \ Create 'do' loop indexes.
@     do
@       i               \ Read pointer.
@       '$' emit        \ Type a '$' sign for a hex number.
@       i 8 u.r         \ Print the address in 8 colums.
@       16
@       for
@         space         \ Print space separator.
@         dup @ 8 u.r   \ Print word in 8 columns.
@         4+            \ Increment address to next word.
@       next
@       16
@     +loop
@     4-                 \ a + u left on the stack.
@     r> base ! ;        \ Restore base.
                COLON       forth_link_address, 0, dmw+, dumpwp
                .word       base, at, tor, hex
                .word       dolit, 16, swap, align
                .word       over, plus, swap
                .word       xdo
                .word       index
2:              .word       dolit, '$', emit
                .word       index, dolit, 8, udotr
                .word       dolit, 4, tor
1:              .word       space
                .word       dupp, at, dolit, 8, udotr
                .word       fourplus
                .word       xnext, 1b
                .word       dolit, 16
                .word       xploop, 2b
                .word       fourminus
                .word       rfrom, base, store
                .word       exit

@ dump ( a u -- )
@ Dump u bytes from a, in a formatted manner.
@
@ : dump
@     base @ >r             \ Save the current base.
@     hex                   \ Work in hexadecimal now.
@     16 swap align         \ Round up the length to the next multiple of 16.
@     over + swap           \ Prepare do-loop limits
@     do
@       cr
@       i dup 16 dm+ drop   \ Print 16 bytes.
@       space space         \ Separators between HEX and ASCII.
@       16 _type            \ Prints ASCII characters.
@       16
@     +loop
@     r> base ! ;           \ Restore base.
                COLON       forth_link_address, 0, dump, dump
                .word       base, at, tor, hex
                .word       dolit, 16, swap, align
                .word       over, plus, swap
                .word       xdo
1:              .word       cr
                .word       index, dupp
                .word       dolit, 16, dumpp, drop
                .word       space, space
                .word       dolit, 16, utype
                .word       dolit, 16
                .word       xploop, 1b
                .word       rfrom, base, store
                .word       exit

@ dumpw ( a u -- )
@ Dump u bytes from a as 32 bit words, in a formatted manner.
@
@ : dumpw
@     base @ >r             \ Save the current base.
@     hex                   \ Work in hexadecimal now.
@     16 swap align         \ Round up the length to the next multiple of 16.
@     over + swap           \ Prepare do-loop limits
@     do
@       cr
@       i dup 4 dm+ drop    \ Print 16 bytes in 4 32 bit words.
@     16 +loop
@     r> base ! ;           \ Restore base.
                COLON       forth_link_address, 0, dumpw, dumpw
                .word       base, at, tor, hex
                .word       dolit, 16, swap, align
                .word       over, plus, swap
                .word       xdo
1:              .word       cr
                .word       index, dupp
                .word       dolit, 4, dumpwp, drop
                .word       dolit, 16
                .word       xploop, 1b
                .word       rfrom, base, store
                .word       exit

@ .s ( ... -- ... )
@ Display the contents of the data stack.
@
@ : .s
@     cr
@     depth               \ Number of stack items to print.
@     >r                  \ Use as flag for 'until'.
@     begin
@       r> pick           \ Fetch next value to print.
@       space .           \ Print it preceeded by a space.
@     until
@     ."| <sp" ;
                COLON       forth_link_address, 0, .s, dots
                .word       cr
                .word       depth
                .word       tor
                .word       branch, dots2
dots1:          .word       rat, pick, space, dot
dots2:          .word       xnext, dots1
                .word       dotqp
                .byte       dots_strend - . - 1
                .ascii      " <tos"
dots_strend:    .align      2, 0
                .word       exit

                COLON       forth_link_address, 0, clscr, clscr
                .word       dotqp
                .byte       clscr_strend - . - 1
                .ascii      "\x1b[2J"
clscr_strend:   .align      2, 0
                .word       exit

                COLON       forth_link_address, 0, crsr_red, crsr_red
                .word       dotqp
                .byte       crsr_red_strend - . -1
                .ascii      "\x1b[31m"
crsr_red_strend:.align      2, 0
                .word       exit

@ page ( -- )
@ Clear the display and place the cursor on the top left corner.
                COLON       forth_link_address, 0, page, page
                .word       dotqp
                .byte       page_strend - . - 1
                .ascii      "\x1b[2J\x1b[H\x1b[0m"
page_strend:    .align      2, 0
                .word       exit

@ !csp ( -- )
@ Save stack pointer in CSP for error checking.
                COLON       forth_link_address, 0, !csp, stcsp
                .word       spat, csp, store, exit @ save pointer

@ ' ( -- ca )
@ Search context vocabularies for the next word in input stream.
@
@ : '
@     blank word find   \ Search the dictionary for the next word following '
@                       \  in the input stream.
@     if
@       lfa>cfa         \ find returns the LFA.
@     else
@       throw
@     then ;

                make_link   forth_link_address
                .byte       1
                .ascii      "'"
                .align      2, 0
                .equ        tick, . + 1
                ENTER
                .word       blank, word
                .word       find                @ ?defined
                .word       qbranch, 1f
                .word       lfa2cfa
                .word       exit                @ yes, push code address
1:              .word       throw               @ no, error

@ dlength ( -- n )
@ Returns the number of characters of the longest name in the context
@  dictionary.
@
@ : dlength
@     0                 \ Start with 0 length.
@     context @ @       \ This is the address of the vocabulary head pointer.
@     begin
@       dup           \ Dup CFA.
@       lfa>nfa
@       c@            \ Length of this word
@       ~MASKK and    \ Mask off lexicon bits.
@       rot max       \ Find the larger of the two lengths.
@       swap          \ TOS = LFA
@       @ dup 0=
@     until
@     drop ;
                COLON       forth_link_address, 0, dlength, dlength
                .word       dolit, 0
                .word       context, at, at
1:              .word       dupp
                .word       lfa2nfa, cat
                .word       dolit, ~MASKK, andd
                .word       rot, max, swap
                .word       at, dupp, zequ
                .word       qbranch, 1b
                .word       drop
                .word       exit

@ ------------------------------------------------------------------------------
@                    E R R O R   H A N D L I N G
@ ------------------------------------------------------------------------------
@ throw ( err# -- err# )
@ Reset system to current local error frame an update error flag.
@
@ : throw
@       handler @ rp!       \ Restore prev return stack.
@       r> handler !        \ Restore prev handler.
@       r> swap >r          \ exc# on return stack.
@       sp! drop r> ;       \ Restore stack.
                COLON       forth_link_address, 0, throw, throw
                .word       handl, at, rpsto
                .word       rfrom, handl, store
                .word       rfrom, swap, tor, spsto
                .word       drop, rfrom, exit

                .include    "src/core/variables.S"

@ ------------------------------------------------------------------------------
@                               B S P
@ ------------------------------------------------------------------------------
                .if          bsp == nucleo_l476rg
                .include     "src/bsp/nucleo_l476rg/bsp.S"
                .endif

                .include    "src/core/terminal.S"
                .include    "src/core/vocabulary.S"
                .include    "src/core/outer.S"
                .include    "src/core/debug.S"
                .if         COMPILE_EDITOR == 1
                .include    "src/core/fio.S"
                .include    "src/core/editor.S"

@ editor ( -- )
                COLON       forth_link_address, IMMED, editor, editor
                .word       dovoc
                .word       editor_dict @ Vocabulary head pointer.
                .set        editor_word_lfa, forth_link_address
                .align      2, 0
                .endif

                .include    "src/core/loop.S"
                .include    "src/core/boot.S"

@ words ( -- )
@ Lists the words in the context.
@
@ : words
@     cr
@     WORDS_PER_LINE 1+ >r      \ Counter of words in line.
@     mlength                   \ Length of longest word.
@     3 +                       \ Extra padding between words.
@     context @                 \ Words lists the words of the transient
@                               \  context vocabulary.
@     begin
@       @                       \ TOS is LFA to next word.
@       ?dup
@       if
@         r> 1-                 \ Decrement counter of words in this line.
@         dup 0=                \ @ Is it equal to 0?
@         if
@           cr
@           drop WORDS_PER_LINE \ New counter of words in line.
@         then
@         >r                    \ Save counter.
@         dup lfa>nfa
@         dup c@ 5 >>           \ Read lexicon bits.
@         0x30 +                \ Add terminal color offset.
@         textc                 \ Set text color.
@         .id                   \ Print word name.
@         dup >r                \ Save copy of LFA pointer.
@         lfa>nfa c@            \ Get word length.
@         ~MASKK and            \ Mask off lexicon bits.
@         over swap -           \ Calculates how many spaces to print to
@                               \ get to the next column.
@         spaces                \ Print the spaces.
@         r>                    \ Get LFA pointer.
@         nuf?                  \ User break.
@     until
@     then
@     r> drop                   \ Drop word pointer.
@     drop                      \ Drop max word length.
@     txtnormal ;               \ Normal text printout.
                COLON       forth_link_address, 0, words, words
                .word       cr, cr
                .word       dolit, WORDS_PER_LINE + 1, tor
                .word       dlength
                .word       dolit, 3, plus
                .word       context, at
words1:         .word       at
                .word       qdup
                .word       qbranch, words2
                .word       rfrom, oneminus
                .word       dupp, zequ
                .word       qbranch, words3
                .word       cr
                .word       drop, dolit, WORDS_PER_LINE
words3:         .word       tor
                .word       dupp
                .word       lfa2nfa
                .word       dupp, cat
                .word       dolit, 5, rshift
                .word       dolit, 0x30, plus
                .word       textc
                .word       dotid
                .word       dupp, tor
                .word       lfa2nfa, cat
                .word       dolit, ~MASKK, andd
                .word       over, swap, minus, spaces
                .word       rfrom
                .word       nufq
                .word       qbranch, words1
words2:         .word       rdrop
                .word       drop
                .word       txtnormal
                .word       exit

                CODE        forth_link_address, 0, tony, tony
                .word       0
                m_types
                m_next


@ forth ( -- )
@ Make FORTH the context vocabulary.
                COLON       forth_link_address, IMMED, forth, forth
                .word       dovoc
                .word       forth_dict
                .set        forth_word_lfa, forth_link_address
                .align      2, 0

                .set        last_forth_lfa, forth_link_address
                .set        last_editor_lfa, editor_link_address

                .end

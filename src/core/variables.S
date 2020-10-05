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

@ dovar ( -- a )
@ Run time routine for VARIABLE and CREATE.
@ The r> in this definition loads the address of the word following the
@  call to dovar. This would be the return address, which now becomes the
@  word that called the word 'up'.
                COLON       forth_link_address, COMPO, dovar, dovar
                .word       rfrom, exit

@ doconst ( -- k )
@ Run time routine for CONSTANT.
@ The r> in this definition loads the address of the word following the
@  call to dovar. This would be the address of the next word, but in
@  constants, it is actually the value to load in the stack. The next value
@  in the return stack will be the one we'll return to.
                COLON       forth_link_address, COMPO, doconst, doconst
                .word       rfrom, at, exit

@ ------------------------------------------------------------------------------
@         S Y S T E M   A N D   U S E R   V A R I A B L E S
@ ------------------------------------------------------------------------------
@ up ( -- a )
@ Pointer to the user area.
@                CONSTANT    forth_link_address, 0, up, up, ram_variables_start

@ sp0        ( -- a )
@ Pointer to bottom of the data stack.
                CONSTANT    forth_link_address, 0, sp0, szero, psp

@ rp0        ( -- a )
@ Pointer to bottom of the return stack.
                CONSTANT    forth_link_address, 0, rp0, rzero, rsp

@ '?key    ( -- a )
@ Execution vector of ?KEY.
                make_link   forth_link_address
                .byte       (ASMWR + 5)
                .ascii      "'?key"
                .align      2, 0
                .equ        tqkey, . + 1
                m_varconst  tqkey_var
                m_next

@ 'emit ( -- a )
@ Execution vector of EMIT.
                make_link   forth_link_address
                .byte       (ASMWR + 5)
                .ascii      "'emit"
                .align      2, 0
                .equ        temit, . + 1
                m_varconst  temit_var
                m_next

@ 'expect ( -- a )
@ Execution vector of EXPECT.
                make_link   forth_link_address
                .byte       (ASMWR + 7)
                .ascii      "'expect"
                .align      2, 0
                .equ        texpe, . + 1
                m_varconst  texpect_var
                m_next

@ 'tap ( -- a )
@ Execution vector of TAP.
                make_link   forth_link_address
                .byte       (ASMWR + 4)
                .ascii      "'tap"
                .align      2, 0
                .equ        ttap, . + 1
                m_varconst  ttap_var
                m_next

@ 'echo ( -- a )
@ Execution vector of ECHO.
                make_link   forth_link_address
                .byte       (ASMWR + 5)
                .ascii      "'echo"
                .align      2, 0
                .equ        techo, . + 1
                m_varconst  techo_var
                m_next

@ 'prompt ( -- a )
@ Execution vector of PROMPT.
                make_link   forth_link_address
                .byte       (ASMWR + 7)
                .ascii      "'prompt"
                .align      2, 0
                .equ        tprompt, . + 1
                m_varconst  tprompt_var
                m_next

@ 'boot ( -- a )
@ Execution vector of boot. By default points to 'hi'.
                make_link   forth_link_address
                .byte       (ASMWR + 5)
                .ascii      "'boot"
                .align      2, 0
                .equ        tboot, . + 1
                m_varconst  tboot_var
                m_next

@ base ( -- a )
@ Storage of the radix base for numeric I/O.
                VARIABLE    forth_link_address, 0, base, base, base_var

@ tmp        ( -- a )
@ A temporary storage location used in parse and find.
                VARIABLE    forth_link_address, COMPO, tmp, temp, tmp_var

@ span ( -- a )
@ Hold character count received by EXPECT.
                VARIABLE    forth_link_address, 0, span, span, span_var

@ >in ( -- a )
@ Hold the character pointer while parsing input stream.
                VARIABLE    forth_link_address, 0, >in, inn, inn_var

@ #tib        ( -- a )
@ Hold the count of how many bytes in the input buffer need to be parsed.
@ It is followed by the address of the next byte to parse, which is 'tib'.
                VARIABLE    forth_link_address, 0, #tib, ntib, ntib_var

@ csp ( -- a )
@ Hold the stack pointer for error checking.
                VARIABLE    forth_link_address, 0, csp, csp, csp_var

@ 'eval ( -- a )
@ Execution vector of EVAL.
                make_link   forth_link_address
                .byte       (ASMWR + 5)
                .ascii      "'eval"
                .align      2, 0
                .equ        teval, . + 1
                m_varconst  teval_var
                m_next

@ 'number ( -- a )
@ Execution vector of NUMBER?.
                make_link   forth_link_address
                .byte       (ASMWR + 7)
                .ascii      "'number"
                .align      2, 0
                .equ        tnumb, . + 1
                m_varconst  tnumber_var
                m_next

@ hld ( -- a )
@ Holds a pointer where the next character of a numeric string is going to be
@  stored.
                VARIABLE    forth_link_address, 0, hld, hld, hld_var

@ handler ( -- a )
@ Hold the return stack pointer for error handling.
                VARIABLE    forth_link_address, 0, handler, handl, handler_var

@ context ( -- a )
@ Pointer to specify vocabulary search order.
                VARIABLE    forth_link_address, 0, context, context, context_var

@ current ( -- a )
@ Point to the vocabulary to be extended.
                VARIABLE    forth_link_address, 0, current, current, current_var

@ clobber ( -- a )
@ Point to the top of the dictionary.
                VARIABLE    forth_link_address, 0, clobber, clobber, clobber_var

@ padchar ( -- a )
@ Point to the top variable holding the character used for padding.
                VARIABLE    forth_link_address, 0, padchar, padchar, padchar_var

@ dp ( -- a )
@ Point to the top of the dictionary.
                VARIABLE    forth_link_address, 0, dp, dp, dtop_var

@ last ( -- a )
@ Point to the last name in the name dictionary.
                VARIABLE    forth_link_address, 0, last, last, last_var

@ fence ( -- a )
@ Point to the LFA of the last word past and including which it is unwise to
@  forget definitions.
                VARIABLE    forth_link_address, 0, fence, fence, fence_var

@ ------------------------------------------------------------------------------
@         S Y S T E M   A N D   U S E R   C O N S T A N T S
@ ------------------------------------------------------------------------------
@ c/l
@ Constant containing the maximum number of characters per line.
                CONSTANT    forth_link_address, 0, c/l, cslashl, CHARACTERS_PER_LINE

@ r/b
@ Constant containing the maximum number of characters per line.
                CONSTANT    forth_link_address, 0, r/b, rslashb, ROWS_PER_BUFFER

@ b/buf
@ Constant containing the number of bytes per buffer. This number is the
@  product of c/l and r/b.
                CONSTANT    forth_link_address, 0, b/buf, bslashbuf, CHARACTERS_PER_LINE * ROWS_PER_BUFFER

@ ------------------------------------------------------------------------------
@                  F I L E  I O   C O N S T A N T S
@ ------------------------------------------------------------------------------
@ prev
@ A system variable that contains the address of the most recently used buffer.
@ This variable is initialized to FIRST upon boot.
                VARIABLE    forth_link_address, 0, prev, prev, prev_var

@ use
@ A system variable that records the address of the next disk buffer to use
@  when one is needed. The  value  is  initialized to FIRST at boot.
                VARIABLE    forth_link_address, 0, use, use, use_var

@ disk-error
                VARIABLE    forth_link_address, 0, disk-error, diskerror, diskerror_var

@ var
                VARIABLE    forth_link_address, 0, var, var, var_var

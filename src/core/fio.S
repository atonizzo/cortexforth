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

@ The MODIFIED bit also serves as a marker of whether this buffer can be used.
@ If the bit is clear the buffer can be used because its contents have not
@  changed and can be lost.
                .equ        ATTR_BUFFER_UPDATE, (1 << 31)

@ ------------------------------------------------------------------------------
@                              File  I / O
@ ------------------------------------------------------------------------------
                .align      2, 0

@ Each RAM buffer is made up by an attribute word followed by a buffer of
@  size BUFFER_SIZE.

@ first
@ Constant containing the address in RAM of the first buffer
@                CONSTANT    forth_link_address, 0, first, first, BUFFER_MEM_START

                CONSTANT    forth_link_address, 0, ram-buffers, rambuffers, MAX_RAM_BUFFERS

@ limit
@ Constant containing the address in RAM of the first byte after the buffer
@  area.
                CONSTANT    forth_link_address, 0, limit, limit, BUFFER_MEM_START + (MAX_RAM_BUFFERS * RAM_BUFFER_SIZE)

@ This is the total number of 1K buffers the storage memory (Flash) can hold.
                CONSTANT    forth_link_address, 0, capacity, capacity, MAX_FLASH_BLOCKS

                CONSTANT    forth_link_address, 0, battributes, battributes, buffer_attributes_var

@ update  ( -- )
@ Marks a buffer as dirty by setting the buffer's  UPDATE bit in its attribute
@  word.
@
@ : update
@       0 ATTR_BUFFER_UPDATE
@       prev @
@       @m! ;
                COLON       forth_link_address, 0, update, update
                .word       dolit, 0, dolit, ATTR_BUFFER_UPDATE
                .word       prev, at, rmw
                .word       exit

@ buf2addr ( buf# -- a )
@ Given a buffer number returns the address in RAM.
@
@ : bufaddr
@    STM32_FLASH_PAGE_SIZE *
@    BUFFER_MEM_START + ;
                .if 0
                COLON       forth_link_address, 0, buf2addr, buf2addr
                .word       dolit, STM32_FLASH_PAGE_SIZE, star
                .word       dolit, BUFFER_MEM_START, plus
                .word       exit
                .else
                CODE        forth_link_address, 0, buf2addr, buf2addr
                m_dolit     STM32_FLASH_PAGE_SIZE
                m_star
                m_dolit     BUFFER_MEM_START
                m_plus
                m_next
                .endif

@ addr2buf ( a -- buf# )
@ Given a buffer's start address returns the buffer number.
@
@ : bufnumber
@    BUFFER_MEM_START -
@    STM32_FLASH_PAGE_SIZE / ;
                .if 0
                COLON       forth_link_address, 0, addr2buf, addr2buf
                .word       dolit, BUFFER_MEM_START, minus
                .word       dolit, STM32_FLASH_PAGE_SIZE, slash
                .word       exit
                .else
                CODE        forth_link_address, 0, addr2buf, addr2buf
                m_dolit     BUFFER_MEM_START
                m_minus
                m_dolit     STM32_FLASH_PAGE_SIZE
                m_slash
                m_next
                .endif

@ buf2attrib ( buf# -- c )
@ Given a buffer's number returns its attributes.
@
@ : bufnumber
@    4*
@    battributes +
@    @;
                COLON       forth_link_address, 0, buf2attrib, buf2attrib
                .word       fourstar, battributes, plus
                .word       at
                .word       exit

@ +buf (buff-addr -- buff-addr f)
@ Returns the address of the next buffer to use. The f flag is 0 if we traversed
@ the entire buffer ring.
@ : +buf
@     b/buf 4+      \ Total size of the buffer.
@     +             \ Reach the start of the next buffer.
@     dup
@     limit =       \ Are we past the last one?
@     if
@       drop        \
@       first       \ Wrap around and pick the first buffer in the list.
@     then
@     dup
@     prev @ - ;    \ Subtract prev. If 0 we have traversed the entire
@                   \  buffer structure.
                COLON       forth_link_address, 0, +buf, plusbuf
                .word       fourplus
                .word       bslashbuf, plus
                .word       dupp, limit, equal
                .word       qbranch, pbuff1
                .word       drop, dolit, BUFFER_MEM_START
pbuff1:         .word       dupp
                .word       prev, at, minus
                .word       exit

@ block-read ( buffer block#  --- )
@ : block-read
@       (CHARACTERS_PER_LINE * ROWS_PER_BUFFER) *
@       FLASH_MEM_START +
@       swap
@       (CHARACTERS_PER_LINE * ROWS_PER_BUFFER)
@       cmove ;
@                COLON       forth_link_address, 0, block-read, blockread
@                .word       dolit, (CHARACTERS_PER_LINE * ROWS_PER_BUFFER)
@                .word       star
@                .word       dolit, FLASH_MEM_START, plus
@                .word       swap
@                .word       dolit, CHARACTERS_PER_LINE *  ROWS_PER_BUFFER
@                .word       cmove
@                .word       exit

@ block-write ( buffer block# f  --- )
@                COLON       forth_link_address, 0, block-write, blockwrite
@                .word       exit

@ r/w ( buffer block# f  --- )
@ : r/w
@     use @ >r
@     swap sec/blk *    \ Calculate the sector offset.
@     rot use !         \ Save the buffer address.
@     sec/blk 0         \ Limit/index values for do.
@     do
@       2dup
@       swap            \ TOS is now r/w flag.
@       if
@         use @         \ Destination for the transfer.
@         secread
@       else
@         var @
@         secwrite
@       then
@       1+
@       b/sec use +!
@    loop
@    2drop
@    r> use ! ;

@ r/w ( buffer blk# f  --- )
@ : r/w
@     if
@                       \ Read operation.
@       blk-rd          \ Provided by the BSP.
@     else
@       blk-wr          \ Provided by the BSP.
@     then ;            \ Restore USE.
                COLON       forth_link_address, 0, r/w, rslashw
                .word       qbranch, rslashw1
                .word       blkrd
                .word       exit
rslashw1:       .word       blkwr
rslashw2:       .word       exit

@ buffer ( blk# -- addr )
@ Given a block number returns a buffer to be used to hold the block's contents.
@
@ : buffer
@    use @                  \ Get address of buffer to use next.
@    dup >r                 \ Save copy.
@    begin                  \ Search for next buffer to use.
@      +buf
@    until
@    use !                  \ The address returned by +buf is the new value of
@                           \  use.
@    r@ @                   \
@    ATTR_BUFFER_UPDATE and \
@    if                     \
@                           \ The UPDATE bit is set and the block must be saved
@                           \  to the disk.
@        r@ 4+              \ Data area for this buffer.
@        r@ @               \ Read attribute word.
@        ~ATTR_BUFFER_UPDATE and \ Mask off UPDATE bit leaving only the number
@                           \  of the block to write to the disk.
@        0                  \ Write operation.
@        r/w                \ write to Flash.
@    then
@    r@ !                   \ Store the buffer number in the attribute word.
@    r@ prev !              \ Store next prev.
@    rfrom 4+ ;             \ Points ot the next buffer area.
                COLON       forth_link_address, 0, buffer, buffer
                .word       use
                .word       at, dupp, tor
buffer1:        .word       plusbuf
                .word       qbranch, buffer1
                .word       use, store
                .word       rat, at
                .word       dolit, ATTR_BUFFER_UPDATE, andd
                .word       qbranch, buffer2
                .word       rat, fourplus
                .word       rat, at
                .word       dolit, (~ATTR_BUFFER_UPDATE & 0xFFFFFFFF), andd
                .word       dolit, 0
                .word       rslashw
buffer2:        .word       rat, store
                .word       rat, prev, store
                .word       rfrom, fourplus
                .word       exit

@ block ( blk# -- a )
@ Given a block number, loads it from memory.
@
@: block
@    0 disk-error !
@    >r                 \ Save copy.
@    prev @             \ Get the last referenced block.
@    dup
@    @                  \ Get buffer status word.
@    0xFFFF and         \ Retain only the block number.
@    r@ <>              \ Is the block the same as prev?
@    if
@      begin
@        +buf           \ Get next buffer.
@        0=             \
@        if             \
@          drop         \ We have gone around the buffer ring without finding
@                       \  one that hosts this block #.
@          r@           \ Retrieve block number.
@          buffer       \ Ask for a buffer to be allocated for this block.
@          dup
@          r@
@          0 disk-error !
@          TRUE r/w     \ Read operation.
@          4-           \ Point to the buffer status word.
@        then
@        dup @          \ New buffer status word.
@        BLOCK_NUMBER_MASK and \ Mask off
@        r@ =           \ Is it the right one?
@      until
@      dup prev !
@      disk-error @
@      if
@        update
@      then
@    then
@    r> drop            \ Remove the block number from the return stack.
@    buf2addr ;         \ Return the adddress of the first byte of the block.
                COLON       forth_link_address, 0, block, block
                .word       dolit, 0, diskerror, store
                .word       tor
                .word       prev, at, dupp, buf2attrib
                .word       dolit, 0xFFFF, andd
                .word       rat, nequal
                .word       qbranch, block1
block3:
                __break__
                .word       plusbuf, zequ
                .word       qbranch, block2
                .word       drop, rat, buffer
                .word       dupp, rat
                .word       dolit, 0, diskerror, store
                .word       dolit, TRUE
                .word       rslashw
                .word       fourminus
block2:         .word       dupp, at
                .word       dolit, (~ATTR_BUFFER_UPDATE & 0xFFFFFFFF), andd
                .word       rat, equal
                .word       qbranch, block3
                .word       dupp, prev, store
                .word       diskerror, at
                .word       qbranch, block1
                .word       update
block1:         .word       rfrom, drop
                .word       buf2addr
                .word       exit

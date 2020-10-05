ENTRY(start_forth)

MEMORY
{
    CODE (rwx) : ORIGIN = 0x08000000, LENGTH = 1024K
    SRAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        _etext_begin = .;
        *(.vectors)
        *(.text*)
        _etext_end = .;
    } > CODE

    .data :
    {
        _data = .;
        *(.data*)
        _edata = .;
    } > SRAM AT > CODE

    .bss :
    {
        _bss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > SRAM AT > CODE
}

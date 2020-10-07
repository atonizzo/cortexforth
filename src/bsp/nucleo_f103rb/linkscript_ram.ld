ENTRY(start_forth)

/* This is the memory layout for a Nucleo board fitted with an STM32F103RG
  with 96K of memory, rather than the stock STM32F103RB with 20K.*/
MEMORY
{
    CODE (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
    SRAM (rwx) : ORIGIN = 0x20010000, LENGTH = 32K
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

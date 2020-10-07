NAME         = forth
BSP          = nucleo_l476rg

TOOLCHAINDIR = /path/to/gnu/toolchain
TOOLSDIR     = ${TOOLCHAINDIR}/bin
PREFIX       = arm-none-eabi-
LDINCLUDE    = /path/to/libc.a
LDINCLUDE   += /path/to/libgcc.a
STLINK_DEBUG_AGENT  = /path/to/debug/agent
CPFLAGS_BIN = --output-target=binary

# variables
CC      = $(TOOLSDIR)/$(PREFIX)gcc
LD      = $(TOOLSDIR)/$(PREFIX)ld -v
AR      = $(TOOLSDIR)/$(PREFIX)ar
AS      = $(TOOLSDIR)/$(PREFIX)as
CP      = $(TOOLSDIR)/$(PREFIX)objcopy
OD      = $(TOOLSDIR)/$(PREFIX)objdump
SZ      = $(TOOLSDIR)/$(PREFIX)size
DB      = $(TOOLSDIR)/$(PREFIX)gdb
RE      = $(TOOLSDIR)/$(PREFIX)readelf

DEBUG_PRINT = 1

# This is the baudrate to be used by the serial communicaton device.
SERIAL_BAUDRATE=460800

CFLAGS   = -I./asm -Wall -g
CFLAGS  += -mthumb -Wa,-ahls
CFLAGS  += -D__BSP__=$(BSP)
CFLAGS  += -D__USART_BAUDRATE__=$(SERIAL_BAUDRATE)

ifeq ($(BSP),nucleo_l476rg)
        CFLAGS  += -mcpu=cortex-m4
else
        CFLAGS  += -mcpu=cortex-m3
endif

LFLAGS  = -Map $(NAME).map
CPFLAGS_BIN = --output-target=binary
CPFLAGS_HEX = -O ihex
ODFLAGS	= -S
REFLAGS	= -a

OBJECT_FILES          = obj/forth.o
all:  	$(NAME)
flash:	$(NAME)_flash
debug:
	@ddd --debugger $(DB)
progflash:
	$(STLINK_DEBUG_AGENT)/st-flash --format binary write forth_flash.bin 0x08000000

ASSEMBLE_PRINT = @echo -e "\e[1;34mBuilding $<\e[0m"

$(NAME): $(OBJECT_FILES) src/bsp/${BSP}/linkscript_ram.ld
	@$(LD)  $(LFLAGS) -o $@.elf $(OBJECT_FILES) -T./src/bsp/${BSP}/linkscript_ram.ld
	@$(RE) $(REFLAGS) $(NAME).elf > $(NAME)_readelf.txt
	@$(OD) $(ODFLAGS) $(NAME).elf > $(NAME).asm
	@$(SZ) $(SZFLAGS) $(NAME).elf

$(NAME)_flash: $(OBJECT_FILES) src/bsp/${BSP}/linkscript_flash.ld
	$(LD)  $(LFLAGS) -o $(NAME).elf $(OBJECT_FILES) -T./src/bsp/${BSP}/linkscript_flash.ld
	@$(CP) $(CPFLAGS_HEX) $(NAME).elf $(NAME).hex
	@$(CP) $(CPFLAGS_BIN) $(NAME).elf $(NAME).bin
	@$(RE) $(REFLAGS) $(NAME).elf > $(NAME)_readelf.txt
	@$(OD) $(ODFLAGS) $(NAME).elf > $(NAME).asm
	@echo -e "\e[1;31mCreating $@.bin\e[0m"
	@$(CP) $(CPFLAGS_BIN) $(NAME).elf $(NAME)_flash.bin
	@$(SZ) $(SZFLAGS) $(NAME).elf

obj/%.o: src/core/%.S
	@mkdir -p obj
	$(ASSEMBLE_PRINT)
	$(CC) -c -o obj/$*.o $(CFLAGS) $(DFLAGS) $< > $*.lst

clean:
	@rm -rf obj *.asm
	@rm -f $(NAME) $(NAME)_flash $(NAME)_flash.* $(NAME).*
	@rm -f $(NAME)_readelf.txt
	@rm -rf dbg_remote

program: $(NAME)_flash
	@$(TEXANEDIR)/st-flash write forth.bin 0x08000000


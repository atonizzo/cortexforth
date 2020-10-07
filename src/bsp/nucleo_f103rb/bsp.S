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

@ This code must provide the following functions or words as a minimum:
@
@ hwsetup ( -- )
@ Sets up the core. At a minimum initializes:
@ - PLL
@ - Serial port
@ - LEDs
@               COLON       0, hwsetup, hwsetup
@               ...
@               EXIT
@
@ ?rx ( -- c T | F)
@ Reads a character from the serial port. Returns the character (and TRUE) if
@  a character is available, or FALSE if no character is available.
@               COLON       0, ?rx, qrx
@               ...
@               EXIT
@
@ tx! ( c -- )
@ Send character c to the output device.
@               COLON       0, tx!, txsto
@               ...
@               EXIT
@
@ For the sake of speed these functions can be CODE words.
@
@ ------------------------------------------------------------------------------
@                        C L O C K   S E T T I N G S
@ ------------------------------------------------------------------------------
                .equ        HSI_FREQUENCY,      8000000
                .equ        HSE_FREQUENCY,      8000000
                .equ        PLL_INPUT_SRC,      0

                .if         (PLL_INPUT_SRC == 0)
                @ HSI is reference clock for PLL.
                .equ        PLL_OUTPUT,         (HSI_FREQUENCY / 2 * PLL_MULTIPLIER)
                .equ        PLL_MULTIPLIER,     8
                .equ        AHB_PRESCALER,      1
                .equ        APB1_PRESCALER,     1
                .equ        APB2_PRESCALER,     1
                .else
                .err        Define values for HSE as input source.
                .endif

                .equ        HCLK_FREQUENCY,     (PLL_OUTPUT/AHB_PRESCALER)
                .equ        APB1_FREQUENCY,     (HCLK_FREQUENCY/APB1_PRESCALER)
                .if         (APB1_FREQUENCY > 36000000)
                .err        APB1 frequency too high.
                .endif
                .equ        APB2_FREQUENCY,     (HCLK_FREQUENCY/APB2_PRESCALER)
                .if         (APB2_FREQUENCY > 72000000)
                .err        APB2 frequency too high.
                .endif

                .if         AHB_PRESCALER == 1
                .equ        AHB_PRESCALER_BITS, 0
                .else
                .if         AHB_PRESCALER == 2
                .equ        AHB_PRESCALER_BITS, 8
                .else
                .if         AHB_PRESCALER == 4
                .equ        AHB_PRESCALER_BITS, 9
                .else
                .if         AHB_PRESCALER == 8
                .equ        AHB_PRESCALER_BITS, 10
                .else
                .if         AHB_PRESCALER == 16
                .equ        AHB_PRESCALER_BITS, 11
                .else
                .if         AHB_PRESCALER == 64
                .equ        AHB_PRESCALER_BITS, 12
                .else
                .if         AHB_PRESCALER == 128
                .equ        AHB_PRESCALER_BITS, 13
                .else
                .if         AHB_PRESCALER == 256
                .equ        AHB_PRESCALER_BITS, 14
                .else
                .if         AHB_PRESCALER == 512
                .equ        AHB_PRESCALER_BITS, 15
                .else
                .err        Wrong value for AHB_PRESCALER
                .endif
                .endif
                .endif
                .endif
                .endif
                .endif
                .endif
                .endif
                .endif

                .if         APB1_PRESCALER == 1
                .equ        APB1_PRESCALER_BITS, 0
                .else
                .if         APB1_PRESCALER == 2
                .equ        APB1_PRESCALER_BITS, 4
                .else
                .if         APB1_PRESCALER == 4
                .equ        APB1_PRESCALER_BITS, 5
                .else
                .if         APB1_PRESCALER == 8
                .equ        APB1_PRESCALER_BITS, 6
                .else
                .if         APB1_PRESCALER == 16
                .equ        APB1_PRESCALER_BITS, 7
                .else
                .err        Wrong value for APB1_PRESCALER
                .endif
                .endif
                .endif
                .endif
                .endif

                .if         APB2_PRESCALER == 1
                .equ        APB2_PRESCALER_BITS, 0
                .else
                .if         APB2_PRESCALER == 2
                .equ        APB2_PRESCALER_BITS, 4
                .else
                .if         APB2_PRESCALER == 4
                .equ        APB2_PRESCALER_BITS, 5
                .else
                .if         APB2_PRESCALER == 8
                .equ        APB2_PRESCALER_BITS, 6
                .else
                .if         APB2_PRESCALER == 16
                .equ        APB2_PRESCALER_BITS, 7
                .else
                .err        Wrong value for APB2_PRESCALER
                .endif
                .endif
                .endif
                .endif
                .endif

@ ------------------------------------------------------------------------------
@        S T M 3 2  H A R D W A R E   D E P E N D E N T   V A L U E S
@ ------------------------------------------------------------------------------
@ This is where the RAM allocated to blocks begins.
                .equ        BUFFER_MEM_START, 0x20014000

@ The RAM allocated to buffers in this BSP is 16K. A buffer is made up of an
@  attribute word plus a 1024 edit area (for a total of 1028 bytes).
                .equ        MAX_RAM_BUFFERS, 3

@ This is where the Flash allocated to blocks begins.
                .equ        BLOCK_STORAGE_FLASH, 0x08010000

@ This BSP allocates 128KB of memory to hold 64 blocks. Although the each
@  screen is 1024 bytes, each block is 2K because that is the size of a flash
@  page in this CPU (minimum erasable page size).
                .equ        MAX_FLASH_BLOCKS, 64

                .equ        STM32_FLASH_PAGE_SIZE, 2048


@ ------------------------------------------------------------------------------
@                               R C C
@ ------------------------------------------------------------------------------
                .equ        AHB_BASE,           0x40018000
                .equ        APB1_BASE,          0x40000000
                .equ        APB2_BASE,          0x40010000

                .equ        AHB_RCC_OFFSET,     0x9000
                .equ        AHB_FLASH_OFFSET,   0xA000
                .equ        APB1_USART2_OFFSET, 0x4400
                .equ        APB1_USART3_OFFSET, 0x4800
                .equ        APB1_USART4_OFFSET, 0x4C00
                .equ        APB1_USART5_OFFSET, 0x5000
                .equ        APB2_GPIOA_OFFSET,  0x0800
                .equ        APB2_GPIOB_OFFSET,  0x0C00
                .equ        APB2_USART1_OFFSET, 0x3800

                .equ        RCC_BASE,           (AHB_BASE + AHB_RCC_OFFSET)
                .equ        USART1_BASE,        (APB2_BASE + APB2_USART1_OFFSET)
                .equ        USART2_BASE,        (APB1_BASE + APB1_USART2_OFFSET)

                .equ        RCC_CR_OFFSET,      0x00
                .equ        RCC_CFGR_OFFSET,    0x04
                .equ        RCC_APB2RSTR_OFFSET, 0x0C
                .equ        RCC_APB1RSTR_OFFSET, 0x10
                .equ        RCC_AHBENR_OFFSET,  0x14
                .equ        RCC_APB2ENR_OFFSET, 0x18
                .equ        RCC_APB1ENR_OFFSET, 0x1C
                .equ        RCC_AHBRSTR_OFFSET, 0x28
                .equ        RCC_CFGR2_OFFSET,   0x2C

                .equ        RCC_CR, (RCC_BASE + RCC_CR_OFFSET)
                .equ        RCC_CFGR, (RCC_BASE + RCC_CFGR_OFFSET)
                .equ        RCC_APB2RSTR, (RCC_BASE + RCC_APB2RSTR_OFFSET)
                .equ        RCC_APB1RSTR, (RCC_BASE + RCC_APB1RSTR_OFFSET)
                .equ        RCC_APB2ENR, (RCC_BASE + RCC_APB2ENR_OFFSET)
                .equ        RCC_APB1ENR, (RCC_BASE + RCC_APB1ENR_OFFSET)

                .equ        RCC_CR_BITS_HSION,  (1 << 0)
                .equ        RCC_CR_BITS_HSIRDY, (1 << 1)
                .equ        RCC_CR_BITS_HSEON,  (1 << 16)
                .equ        RCC_CR_BITS_HSERDY, (1 << 17)
                .equ        RCC_CR_BITS_PLLON,  (1 << 24)
                .equ        RCC_CR_BITS_PLLRDY, (1 << 25)

                .equ        RCC_CFGR_BITS_SW_HSI,    (0 << 0)
                .equ        RCC_CFGR_BITS_SW_HSE,    (1 << 0)
                .equ        RCC_CFGR_BITS_SW_PLL,    (2 << 0)
                .equ        RCC_CFGR_BITS_SW_ALL,    (3 << 0)
                .equ        RCC_CFGR_BITS_SWS_HSI,   (0 << 2)
                .equ        RCC_CFGR_BITS_SWS_HSE,   (1 << 2)
                .equ        RCC_CFGR_BITS_SWS_PLL,   (2 << 2)
                .equ        RCC_CFGR_BITS_SWS_ALL,   (3 << 2)

                .equ        RCC_APB2RSTS_BITS_USART1RST, (1 << 14)

                .equ        RCC_APB1RSTS_BITS_USART4RST, (1 << 19)

                .equ        RCC_APB2ENR_BITS_USART1EN,  (1 << 14)
                .equ        RCC_APB1ENR_BITS_USART4EN,  (1 << 19)

@ ------------------------------------------------------------------------------
@                               F L A S H
@ ------------------------------------------------------------------------------
                .equ        FLASH_BASE, (AHB_BASE + AHB_FLASH_OFFSET)

                .equ        FLASH_ACR_OFFSET, 0
                .equ        FLASH_KEYR_OFFSET, 0x04
                .equ        FLASH_OPTKEYR_OFFSET, 0x08
                .equ        FLASH_SR_OFFSET, 0x0C
                .equ        FLASH_CR_OFFSET, 0x10
                .equ        FLASH_AR_OFFSET, 0x14
                .equ        FLASH_OBR_OFFSET, 0x1C
                .equ        FLASH_WRPR_OFFSET, 0x20

                .equ        FLASH_ACR,      (FLASH_BASE + FLASH_ACR_OFFSET)
                .equ        FLASH_KEYR,     (FLASH_BASE + FLASH_KEYR_OFFSET)
                .equ        FLASH_SR,       (FLASH_BASE + FLASH_SR_OFFSET)
                .equ        FLASH_CR,       (FLASH_BASE + FLASH_CR_OFFSET)
                .equ        FLASH_AR,       (FLASH_BASE + FLASH_AR_OFFSET)

                .equ        FLASH_ACR_0WS, 0
                .equ        FLASH_ACR_1WS, 1
                .equ        FLASH_ACR_2WS, 2
                .equ        FLASH_ACR_WS_ALL, 7

                .equ        FLASH_SR_BITS_BSY,      (1 << 0)
                .equ        FLASH_SR_BITS_PGERR,    (1 << 2)
                .equ        FLASH_SR_BITS_WRPRTERR, (1 << 4)
                .equ        FLASH_SR_BITS_EOP,      (1 << 5)

                .equ        FLASH_CR_BITS_PG,       (1 << 0)
                .equ        FLASH_CR_BITS_PER,      (1 << 1)
                .equ        FLASH_CR_BITS_MER,      (1 << 2)
                .equ        FLASH_CR_BITS_STRT,     (1 << 6)
                .equ        FLASH_CR_BITS_LOCK,     (1 << 7)

                .equ        UNLOCK_KEY1, 0x45670123
                .equ        UNLOCK_KEY2, 0xCDEF89AB

                .equ        STM32_FLASH_PAGE_SIZE, 2048

@ This is the offset in RAM between the code for fwri and ferase.
                .equ        FERASE_RAM_OFFSET, 512

@ ------------------------------------------------------------------------------
@                               U S A R T
@ ------------------------------------------------------------------------------
                .equ        TERM_USART_NUMBER,  1
                .if         TERM_USART_NUMBER == 1
                .equ        TERM_USART_BASE, USART1_BASE
                .equ        TERM_USART_FREQUENCY, APB2_FREQUENCY
                .equ        TERM_USART_TX_PIN_PORT,  PIN_PORT_A
                .equ        TERM_USART_TX_PIN_BIT,   9
                .equ        TERM_USART_RX_PIN_PORT,  PIN_PORT_A
                .equ        TERM_USART_RX_PIN_BIT,   10
                .equ        TERM_USART_ENABLE_BIT, (1 << 14)
                .equ        TERM_USART_ENABLE_REGISTER, RCC_APB2ENR
                .equ        TERM_USART_RESET_BIT, (1 << 14)
                .equ        TERM_USART_RESET_REGISTER, RCC_APB2RSTR
                .else
                .if         TERM_USART_NUMBER == 2
                .equ        TERM_USART_BASE, USART2_BASE
                .equ        TERM_USART_FREQUENCY, APB1_FREQUENCY
                .equ        TERM_USART_TX_PIN_PORT,  PIN_PORT_A
                .equ        TERM_USART_TX_PIN_BIT,   2
                .equ        TERM_USART_RX_PIN_PORT,  PIN_PORT_A
                .equ        TERM_USART_RX_PIN_BIT,   3
                .equ        TERM_USART_ENABLE_BIT, (1 << 17)
                .equ        TERM_USART_ENABLE_REGISTER, RCC_APB1ENR
                .equ        TERM_USART_RESET_BIT, (1 << 17)
                .equ        TERM_USART_RESET_REGISTER, RCC_APB21STR
                .else
                .err        Define UART port number.
                .endif
                .endif

                .equ        USART_SR_OFFSET,           0x00
                .equ        USART_DR_OFFSET,           0x04
                .equ        USART_BRR_OFFSET,          0x08
                .equ        USART_CR1_OFFSET,          0x0C
                .equ        USART_CR2_OFFSET,          0x10
                .equ        USART_CR3_OFFSET,          0x14
                .equ        USART_GTPR_OFFSET,         0x18

                .equ        TERM_USART_BRR,    (TERM_USART_BASE + USART_BRR_OFFSET)
                .equ        TERM_USART_CR1,    (TERM_USART_BASE + USART_CR1_OFFSET)

                .equ        TERM_USART_MANTISSA,  (TERM_USART_FREQUENCY / 16 / TERM_USART_BAUDRATE)
                .equ        TERM_USART_FRACTIONAL, (2 * TERM_USART_FREQUENCY - 32 * TERM_USART_MANTISSA * TERM_USART_BAUDRATE + TERM_USART_BAUDRATE) / (2 * TERM_USART_BAUDRATE)
                .equ        USART_BRR_VALUE, (TERM_USART_MANTISSA << 4) | TERM_USART_FRACTIONAL

                .equ        USART_CR1_RE,              (1 << 2)
                .equ        USART_CR1_TE,              (1 << 3)
                .equ        USART_CR1_UE,              (1 << 13)

                .equ        USART_SR_RXNE,             (1 << 5)
                .equ        USART_SR_TXE,              (1 << 7)

@ ------------------------------------------------------------------------------
@                               G P I O
@ ------------------------------------------------------------------------------
                .equ        GPIOA_BASE, (APB2_BASE + APB2_GPIOA_OFFSET)
                .equ        GPIOB_BASE, (APB2_BASE + APB2_GPIOB_OFFSET)

                .equ        GPIO_CRL_OFFSET, (0x00)
                .equ        GPIO_CRH_OFFSET, (0x04)
                .equ        GPIO_IDR_OFFSET, (0x08)
                .equ        GPIO_ODR_OFFSET, (0x0C)
                .equ        GPIO_BSRR_OFFSET, (0x10)
                .equ        GPIO_BRR_OFFSET, (0x14)
                .equ        GPIO_LCKR_OFFSET, (0x18)

                .equ        GPIOA_BSRR, (GPIOA_BASE + GPIO_BSRR_OFFSET)

                .equ        PIN_MODE_INPUT,         0
                .equ        PIN_MODE_OUTPUT_10M,    1
                .equ        PIN_MODE_OUTPUT_2M,     2
                .equ        PIN_MODE_OUTPUT_50M,    3

                .equ        PIN_CNF_INPUT_ANALOG,           0
                .equ        PIN_CNF_INPUT_FLOATING,         1
                .equ        PIN_CNF_INPUT_PUPD,             2
                .equ        PIN_CNF_OUTPUT_GPIO_PUSHPULL,   0
                .equ        PIN_CNF_OUTPUT_GPIO_OD,         1
                .equ        PIN_CNF_OUTPUT_ALT_PUSHPULL,    2
                .equ        PIN_CNF_OUTPUT_ALT_OD,          3

                .equ        PIN_PORT_A, 0
                .equ        PIN_PORT_B, 1
                .equ        PIN_PORT_C, 2
                .equ        PIN_PORT_D, 3
                .equ        PIN_PORT_E, 4
                .equ        PIN_PORT_F, 5
                .equ        PIN_PORT_G, 6

@ ------------------------------------------------------------------------------
@                     T E R M I N A L   W O R D S
@ ------------------------------------------------------------------------------
@ ?rx ( -- c T | F)
@ Reads a character from the serial port. Returns the character (and TRUE) if
@  a character is available, or FALSE if no character is available.
                CODE        forth_link_address, 0, ?rx, qrx
                PUSHH       TOS, PSP
                movi32      WREG1 , TERM_USART_BASE
                ldr         TOS, [WREG1, USART_SR_OFFSET]
                ands        TOS, #USART_SR_RXNE
                ittt        ne
                ldrbne      TOS, [WREG1, USART_DR_OFFSET]
                strne       TOS, [PSP], 4
                movne       TOS, #TRUE
                NEXT

@ The core of the uart_tx_char is placed in a macro because it is also used
@  by the 'emit' word.
                .macro      m_uart_tx_char
                movi32      WREG1, TERM_USART_BASE
                ldr         WREG2, [WREG1, USART_SR_OFFSET]
                ands        WREG2, #USART_SR_TXE
                beq         .-6
                strb        TOS, [WREG1, USART_DR_OFFSET]
                .endm

@ tx! ( c -- )
@ Send character c to the output device.
                CODE        forth_link_address, 0, tx!, txsto
                m_uart_tx_char
                POPP        TOS, PSP
                NEXT

@ bsp_howdy ( -- )
@ Called during the boot to print out a BSP specific greeting. It can also be
@  used for final BSP initialization
                COLON       forth_link_address, 0, bsp_howdy, bsp_howdy
                .word       dotqp
                .byte       bsp_greet_strend - . - 1
                .ascii      "STM32 Nucleo F103RB BSP"
bsp_greet_strend:
                .align      2, 0
                .word       exit

@ ------------------------------------------------------------------------------
@                               G P I O
@ ------------------------------------------------------------------------------
                .macro      conf_gpio port, bit, conf, mode, preset
                .word       dolit, 0, dolit, (1 << (\port + 2))
                .word       dolit, RCC_APB2ENR, rmw
                .if         \bit > 7
                .word       dolit, (15 << ((\bit - 8) * 4)), dolit, (((\conf << 2) | \mode) << ((\bit - 8) * 4))
                .word       dolit, GPIOA_BASE + ((GPIOB_BASE - GPIOA_BASE) * \port) + GPIO_CRH_OFFSET, rmw
                .else
                .word       dolit, (15 << (\bit * 4)), dolit, (((\conf << 2) | \mode) << (\bit * 4))
                .word       dolit, GPIOA_BASE + ((GPIOB_BASE - GPIOA_BASE) * \port) + GPIO_CRL_OFFSET, rmw
                .endif
                .if         \preset == 1
                .word       dolit, 0, dolit, (1 << \bit)
                .else
                .word       dolit, 0, dolit, (1 << (\bit + 16))
                .endif
                .word       dolit, GPIOA_BASE + ((GPIOB_BASE - GPIOA_BASE) * \port) + GPIO_CRL_OFFSET, rmw
                .endm
                .word       exit

@ gpio-set ( b p -- )   Sets GPIO bit b in port p.
@
@ : gpio_set
@     APB2_GPIOB_OFFSET - APB2_GPIOA_OFFSET * \ Find base address of port
@                                             \  registers.
@     GPIOA_BSRR +                            \ Add register offset.
@     >r                                      \
@     1 swap <<                               \ Calculate bit mask.
@     r>                                      \
@     ! ;                                     \ Write mask in GPIO_BSRR.
                .macro      m_gpio_set
                m_dolit     (APB2_GPIOB_OFFSET - APB2_GPIOA_OFFSET)
                m_smull
                m_drop
                m_dolit     GPIOA_BSRR
                m_plus
                m_tor
                m_dolit     1
                m_swap
                m_lshiftl
                m_rfrom
                m_store
                .endm

                CODE        forth_link_address, 0, gpio-set, gpio_set
                m_gpio_set
                m_next

@ gpio-clear ( b p -- )   Clears GPIO bit b in port p.
@
                .macro      m_gpio_clear
                m_swap
                m_dolit     16
                m_plus
                m_swap
                m_gpio_set
                .endm

                CODE        forth_link_address, 0, gpio-clear, gpio_clear
                m_gpio_clear
                m_next

@ ------------------------------------------------------------------------------
@                               L E D
@ ------------------------------------------------------------------------------
                .equ       LED_PORT, PIN_PORT_A
                .equ       LED_BIT, 5

@ led-on ( -- ) Turn on the LED.
                COLON       forth_link_address, 0, led-on, ledon
                .word       dolit, LED_BIT, dolit, LED_PORT
                .word       gpio_set
                .word       exit

@ led-off ( -- ) Turn off the LED.
                COLON       forth_link_address, 0, led-off, ledoff
                .word       dolit, LED_BIT, dolit, LED_PORT
                .word       gpio_clear
                .word       exit

@ ------------------------------------------------------------------------------
@                            M C U    S E T U P
@ ------------------------------------------------------------------------------
@ hwsetup ( -- )
@ Set sup the core.
@ - Programs the PLL
@ - Programs the serial port.
@ - Sets PC12 as output (LED)
                COLON       forth_link_address, 0, hwsetup, hwsetup

@ Program the Flash wait states.
                .word       dolit, 7
                .if         HCLK_FREQUENCY < 24000000
                .word       dolit, 0
                .else
                .if         HCLK_FREQUENCY < 48000000
                .word       dolit, 1
                .else
                .word       dolit, 2
                .endif
                .endif
                .word       dolit, FLASH_ACR, rmw

@ Check if we are alreding running on internal oscillator.
                .word       dolit, RCC_CFGR, at
                .word       dolit, RCC_CFGR_BITS_SWS_ALL, andd
                .word       dolit, RCC_CFGR_BITS_SWS_HSI, nequal
                .word       qbranch, hwsetup1

@ Check if the internal oscillator is already enabled.
                .word       dolit, RCC_CR, at
                .word       dolit, RCC_CR_BITS_HSIRDY, andd
                .word       zequ
                .word       qbranch, hwsetup3

@ Enable HSI now and loop until ready.
                .word       dolit, 0, dolit, RCC_CR_BITS_HSION
                .word       dolit, RCC_CR, rmw
hwsetup2:       .word       dolit, RCC_CR, at
                .word       dolit, RCC_CR_BITS_HSIRDY, andd
                .word       qbranch, hwsetup2

@ Switch to HSI and wait until switch complete.
hwsetup3:       .word       dolit, RCC_CFGR_BITS_SW_ALL
                .word       dolit, RCC_CFGR_BITS_SW_HSI
                .word       dolit, RCC_CFGR, rmw
hwsetup4:       .word       dolit, RCC_CFGR, at
                .word       dolit, RCC_CFGR_BITS_SWS_ALL, andd
                .word       dolit, RCC_CFGR_BITS_SWS_HSI, equal
                .word       qbranch, hwsetup4

hwsetup1:
@ Enable external oscillator and wait until it is ready.
@                .word       dolit, 0, dolit, RCC_CR_BITS_HSEON
@                .word       dolit, RCC_CR, rmw
@hwsetup5:       .word       dolit, RCC_CR, at
@                .word       dolit, RCC_CR_BITS_HSERDY, andd
@                .word       qbranch, hwsetup5

@ PLL must be disabled before being programmed. Loop until disabled.
                .word       dolit, RCC_CR_BITS_PLLON, dolit, 0
                .word       dolit, RCC_CR, rmw
hwsetup6:       .word       dolit, RCC_CR, at
                .word       dolit, RCC_CR_BITS_PLLRDY, andd
                .word       zequ
                .word       qbranch, hwsetup6

@ Program the PLL registers
@ The source of the PLL reference clock is the internal oscillator.
                .word       dolit, (0xF << 18) | (1 << 16) | (7 << 11) | (7 << 8) | (0x0F << 4)
                .word       dolit, ((PLL_MULTIPLIER - 2) << 18) | (APB2_PRESCALER_BITS << 11) | (APB1_PRESCALER_BITS << 8) | (AHB_PRESCALER_BITS << 4)
                .word       dolit, RCC_CFGR, rmw

@ Enable PLL now and loop until enabled.
                .word       dolit, 0, dolit, RCC_CR_BITS_PLLON
                .word       dolit, RCC_CR, rmw
hwsetup7:       .word       dolit, RCC_CR, at
                .word       dolit, RCC_CR_BITS_PLLRDY, andd
                .word       qbranch, hwsetup7

@ Switch to PLL and loop until switch completed.
                .word       dolit, RCC_CFGR_BITS_SW_ALL
                .word       dolit, RCC_CFGR_BITS_SW_PLL
                .word       dolit, RCC_CFGR, rmw
hwsetup8:       .word       dolit, RCC_CFGR, at
                .word       dolit, RCC_CFGR_BITS_SWS_ALL, andd
                .word       dolit, RCC_CFGR_BITS_SWS_PLL, equal
                .word       qbranch, hwsetup8

@ Enable USART.
                .word       dolit, 0, dolit, TERM_USART_ENABLE_BIT
                .word       dolit, TERM_USART_ENABLE_REGISTER, rmw

@ Reset UART.
                .word       dolit, 0, dolit, TERM_USART_RESET_BIT
                .word       dolit, TERM_USART_RESET_REGISTER, rmw
                .word       dolit, TERM_USART_RESET_BIT, dolit, 0
                .word       dolit, TERM_USART_RESET_REGISTER, rmw
@ Set baudrate
                .word       dolit, USART_BRR_VALUE
                .word       dolit, TERM_USART_BRR, store

@ USART is in N81 mode.
                .word       dolit, (USART_CR1_TE | USART_CR1_RE | USART_CR1_UE)
                .word       dolit, TERM_USART_CR1, store

@ Serial port pins configuration.
                conf_gpio   TERM_USART_TX_PIN_PORT, TERM_USART_TX_PIN_BIT, PIN_CNF_OUTPUT_ALT_PUSHPULL, PIN_MODE_OUTPUT_2M, 0
                conf_gpio   TERM_USART_RX_PIN_PORT, TERM_USART_RX_PIN_BIT, PIN_CNF_INPUT_FLOATING, PIN_MODE_INPUT, 0

@ Setup the GPIOs to drive the LEDs.
                conf_gpio   LED_PORT, LED_BIT, PIN_CNF_OUTPUT_GPIO_PUSHPULL, PIN_MODE_OUTPUT_2M, 0
                .word       exit

                .if         COMPILE_EDITOR == 1
@ do-keys  ( -- )     \ Issues the keys to unlock flash operations.
@ : fbusy
@       UNLOCK_KEY1 FLASH_KEYR !
@       UNLOCK_KEY2 FLASH_KEYR !
@     until ;
                COLON       forth_link_address, 0, do-keys, dokeys
                .word       dolit, UNLOCK_KEY1, dolit, FLASH_KEYR, store
                .word       dolit, UNLOCK_KEY2, dolit, FLASH_KEYR, store
                .word       exit

@ bladdr ( blk# -- adr )    \ Returns the address in Flash of a given block.
@                           \ Each block is 2K, which is the smallest erasable
@                           \  area in this chip.
@ : bladdr
@     STM32_FLASH_PAGE_SIZE *   \ Poor man's MMU.
@     BLOCK_STORAGE_FLASH+ ;
                COLON       forth_link_address, 0, bladdr, bladdr
                .word       dolit, STM32_FLASH_PAGE_SIZE, star
                .word       dolit, BLOCK_STORAGE_FLASH, plus
                .word       exit

@ fbusy  ( -- )     \ Wait for the BSY bit in the FLASH_SR register to clear.
@ : fbusy
@     begin
@       FLASH_SR @
@       FLASH_SR_BITS_BSY and
@       0=
@     until ;
                .macro      m_fbusy
1:              m_dolit     FLASH_SR
                m_at
                m_dolit     FLASH_SR_BITS_BSY
                m_andd
                m_zequ
                m_qbranc    1b
                .endm

                CODE        forth_link_address, 0, fbusy, fbusy
                m_fbusy
                m_next

@ funlock  ( -- )   \ Unlock the Flash array.
@ : funlock
@     FLASH_CR @ FLASH_CR_BITS_LOCK and
@     if
@       do-keys
@     then ;
                COLON       forth_link_address, 0, funlock, funlock
                .word       fbusy
                .word       dolit, FLASH_CR, at
                .word       dolit, FLASH_CR_BITS_LOCK, andd
                .word       qbranch, 1f
                .word       dokeys
1:              .word       exit

@ flock  ( -- )     \ Lock the Flash array.
@ : flock
@     FLASH_CR @ FLASH_CR_BITS_LOCK and
@     if
@       do-keys
@     then ;
                COLON       forth_link_address, 0, flock, flock
                .word       dolit, 0, dolit, FLASH_CR_BITS_LOCK
                .word       dolit, FLASH_CR
                .word       rmw
                .word       exit

@ ferase  ( a -- )              \ Erases a page of the Flash array.
@ For safety reasons it assumes that the flash array has been unlocked before
@  this word is run. Returns either 0 for a correct operation or an error code.
@
@ : ferase
@     0 FLASH_CR_BITS_PER FLASH_CR @m! \ Set the PER bit in FLASH_CR.
@     FLASH_AR !                \ Store the memory address of the page to clear
@                               \  in the FLASH_AR register.
@     0 FLASH_CR_BITS_STRT FLASH_CR @m! \ Start erase.
@     fwbusy ;              \ Loop until busy.
                CODE        forth_link_address, 0, ferase, ferase
                m_dolit     0
                m_dolit     FLASH_CR_BITS_PER
                m_dolit     FLASH_CR
                m_rmw
                m_dolit     FLASH_AR
                m_store
                m_dolit     0
                m_dolit     FLASH_CR_BITS_STRT
                m_dolit     FLASH_CR
                m_rmw
                m_fbusy
                m_next

@ f!  ( h a -- E | F )
@ Writes 16 bit quantity h at address in Flash.
@ For safety reasons it assumes that the flash array has been unlocked before
@  this word is run. Returns either 0 for a correct operation or an error code.
@
@ : f!
@   0 FLASH_SR_BITS_EOP + FLASH_SR_BITS_WRPRTERR + FLASH_SR_BITS_PGERR
@   FLASH_SR @m!
@   0 FLASH_CR_BITS_PG FLASH_CR @!m
@   h!
@   0 FLASH_SR_BITS_EOP FLASH_SR @m!
@   FLASH_SR @
@   FLASH_SR_BITS_WRPRTERR + FLASH_SR_BITS_PGERR and ;
                CODE        forth_link_address, 0, f!, fwri
                m_dolit     0
                m_dolit     FLASH_SR_BITS_EOP + FLASH_SR_BITS_WRPRTERR + FLASH_SR_BITS_PGERR
                m_dolit     FLASH_SR
                m_rmw
                m_dolit     0
                m_dolit     FLASH_CR_BITS_PG
                m_dolit     FLASH_CR
                m_rmw
                m_hstore
                m_fbusy
                m_dolit     0
                m_dolit     FLASH_SR_BITS_EOP
                m_dolit     FLASH_SR
                m_rmw
                m_dolit     FLASH_SR
                m_at
                m_dolit     FLASH_SR_BITS_WRPRTERR + FLASH_SR_BITS_PGERR
                m_andd
                m_next

@ ?bclean  ( strt end -- f )
@ Checks if a block of Flash sta starts at address strt and ends at address end
@  is clean, that is, the Flash in it has been erased.
@ : ?clean
@     swap                      \ do/+loop indices.
@     do
@       I                       \ Address to write to.
@       @                       \ Read flash. 0xFFFFFFFF is clean.
@       1+                      \ Write to flash.
@       if
@         r> drop r> drop       \ Remove loop parameters.
@         drop 0                \ Page not blank.
@         exit
@       then
@     4 +loop
@     1 ;                       \ Drop the source pointer.
                COLON       forth_link_address, 0, ?bclean, qbclean
                .word       swap, xdo
1:              .word       index, at, oneplus
                .word       qbranch, 2f
                .word       rfrom, drop, rfrom, drop
                .word       dolit, 0
                .word       exit
2:              .word       dolit, 4
                .word       xploop, 1b
                .word       dolit, 1
                .word       exit

@ fppage  ( src dest n -- f )   \ Writes data in Flash.
@ For safety reasons it assumes that the flash array has been unlocked before
@  this word is run.
@ : fhwrite
@     2 swap align              \ Align the number of bytes to write to a
@                               \  half-word biundary.
@     STM32_FLASH_PAGE_SIZE min \ We'll program a maximum of one page.
@     over +                    \
@     swap                      \ DO LOOP indexes.
@     do
@       dup h@                  \ Read 16 bits from the source address.
@       I                       \ Address to write to.
@       here execute            \ Write to flash by executing code in RAM.
@       if
@         r> drop r> drop       \ Remove loop parameters.
@         drop -1               \ Error.
@         exit
@       then
@       2+                      \ Increment the source pointer.
@     2 +loop
@     drop 0 ;                  \ Drop the source pointer.
                COLON       forth_link_address, 0, fppage, fppage
                .word       dolit, 2, swap, align
                .word       dolit, STM32_FLASH_PAGE_SIZE, min
                .word       over, plus, swap
                .word       xdo
1:              .word       dupp, hat
                .word       index
                .word       here, execute
                .word       qbranch, 2f
                .word       rfrom, drop, rfrom, drop
                .word       dolit, -1
                .word       branch, 3f
                .word       exit
2:              .word       twoplus
                .word       dolit, 2
                .word       xploop, 1b
                .word       dolit, 0
3:              .word       nip
                .word       exit

@ blk-rd ( dest blk# --- )  \ Read b/buf bytes from a flash block.
@ : sec-read
@     bladdr
@     swap
@     b/sec
@     cmove ;
                COLON       forth_link_address, 0, blk-rd, blkrd
                .word       bladdr, swap, bslashbuf, cmove
                .word       exit

@ blk-wr ( src blk# --- )   \ Writes b/buf bytes to a flash block.
@ This STM32 requires that code that erases and writes to flash be executed
@  from RAM. Because of this the bodies of the fwri and ferase words are
@  self contained CODE words that do not reference anything in flash and are
@  copied in RAM at 'here' (for the fwri code) and at
@  ('here' + FERASE_RAM_OFFSET) for ferase. The code will then execute these
@  words from RAM.
@ : sec-read
@     'fwri' 1-             \ Source.
@     here                  \ Destination.
@     FERASE_RAM_OFFSET     \ Size of copy.
@     cmove                 \ Move the frwi code,
@     'ferase' 1-           \ Source.
@     here FERASE_RAM_OFFSET + \ Destination.
@     FERASE_RAM_OFFSET     \ Size of copy.
@     cmove                 \ Move the ferase code,
@     funlock
@     bladdr dup dup        \ Start address of block in Flash.
@     STM32_FLASH_PAGE_SIZE + \ End address of block in flash.
@     swap ?bclean          \ Is the area of Flash clean?
@     0=
@     if
@       dup
@       here FERASE_RAM_OFFSET + execute    \ Execute code in RAM.
@     then
@     bslashbuf             \ Length of the area to program.
@     fppage ;              \ Program the page.
                COLON       forth_link_address, 0, blk-wr, blkwr
                .word       dolit, fwri, oneminus
                .word       here
                .word       dolit, FERASE_RAM_OFFSET, cmove
                .word       dolit, ferase, oneminus
                .word       here, dolit, FERASE_RAM_OFFSET, plus
                .word       dolit, FERASE_RAM_OFFSET, cmove
                .word       funlock
                .word       bladdr, dupp, dupp
                .word       dolit, STM32_FLASH_PAGE_SIZE, plus
                .word       qbclean, zequ
                .word       qbranch, 1f
                .word       dupp
                .word       here, dolit, FERASE_RAM_OFFSET, plus, execute
1:              .word       bslashbuf
                .word       fppage
                .word       flock
                .word       exit

                .endif

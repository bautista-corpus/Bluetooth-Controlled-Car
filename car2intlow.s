/*
 * File:   This code shows you how to use an 
	    interrupt Service Routine (ISR) using 
	    the external interrupt 0.
     
 * Author: Baltazar Jiménez.
 *
 * Created on March, 2019
 */

    .include "p30F4013.inc"
;---------------------------------------------------------------------------    
    
    ;Clock Switching Operation and 
    ;the Fail-Safe Clock Monitor (FSCM) are disabled.
    ;FSCM allows the device to continue to operate even in the event of 
    ;an oscillator failure.    
    ;FRC 7.37 MHz internal Fast RC oscillator. Enabled
    
    config __FOSC, CSW_FSCM_OFF & FRC
    
;---------------------------------------------------------------------------    
    
    ;Watchdog Timer is disabled
    ;The primary function of the Watchdog Timer (WDT) is to reset the processor
    ;in the event of a software malfunction
    config __FWDT, WDT_OFF 
    
;---------------------------------------------------------------------------    
    
    ;The BOR and POR Configuration bits found in the FBORPOR Configuration 
    ;register are used to set the Brown-out Reset voltage for the device, 
    ;enable the Brown-out Reset circuit, and set the Power-up Timer delay time.
    ;For more information on these Configuration bits, please refer to 
    ;Section 8. "Reset?.
    
;    POR: Power-on Reset
;   There are two threshold voltages associated with a Power-on Reset (POR). 
;    The first voltage is the device threshold voltage, V POR . The device 
;    threshold voltage is the voltage at which the device logic circuits become 
;    operable. The second voltage associated with a POR event is the POR circuit 
;    threshold voltage which is nominally 1.85V.
    
;    Brown-out Reset (BOR) module is based on an internal voltage reference 
    ;circuit. The main purpose of the BOR module is to generate a device Reset
    ;when a brown-out condition occurs. Brown-out conditions are generally 
    ;caused by glitches on the AC mains (i.e., missing waveform portions of the 
    ;AC cycles due to bad power transmission lines), or voltage sags due to 
    ;excessive current draw when a large load is energized.
    
;    TPWRT = Additional ?power-up? delay as determined by the FPWRT<1:0>
;   configuration bits. This delay is 0 ms, 4 ms, 16 ms or 64 ms nominal.
    
;    EXTR: External Reset (MCLR) Pin bit enabled
    ;RCON: Reset Control Register
    
    config __FBORPOR, PBOR_ON & BORV27 & PWRT_16 & MCLR_EN
    
;---------------------------------------------------------------------------      
    
;    General Code Segment Configuration Bits
;The general code segment Configuration bits in the FGS Configuration register 
;    are used to code-protect or write-protect the user program memory space. 
;    The general code segment includes all user program memory with the exception
;    of the interrupt vector table space (0x000000-0x0000FE).
;If the general code segment is code-protected by programming the GCP 
;    Configuration bit (FGS<1>) to a ?0?, the device program memory cannot be 
;    read from the device using In-Circuit Serial Programming (ICSP), or the 
;    device programmer. Additionally, further code cannot be programmed into the 
;    device without first erasing the entire general code segment.
;    When the general segment is code-protected, user code can still access the 
;    program memory data via table read instructions, or Program Space Visibility
;    (PSV) accesses from data space. 
;    If the GWRP (FGS<0>) Configuration bit is programmed, all writes to the 
;    user program memory space are disabled.    
    
    config __FGS, CODE_PROT_OFF & GWRP_OFF

;..............................................................................
;Program Specific Constants (literals used in code)
;..............................................................................

    .equ SAMPLES, 64         ;Number of samples

    baud    = 9600                         ; UART1 Baud rate, Baud
    ;fcyc    = 7372800*16/4                  ; MCU machine cycle frequency, Hz
    fcyc    = 1843200                ; MCU machine cycle frequency, Hz
    baudrate = (((fcyc/baud)/16)-1)         ; Calculated BRG value

;..............................................................................
;Global Declarations:
;..............................................................................

    .global _wreg_init       ;Provide global scope to _wreg_init routine
                                 ;In order to call this routine from a C file,
                                 ;place "wreg_init" in an "extern" declaration
                                 ;in the C file.

    .global __reset          ;The label for the first line of code.
    .GLOBAL	__U1RXInterrupt
    ;.GLOBAL	__U1TXInterrupt
;..............................................................................
;Constants stored in Program space
;..............................................................................

    .section .myconstbuffer, code
    .palign 2                ;Align next word stored in Program space to an
                                 ;address that is a multiple of 2
ps_coeff:
    .hword   0x0002, 0x0003, 0x0005, 0x000A
    
MESSAGE:
;.BYTE   0X01, 0X02, 0X04, 0X08, 0X10, 0X20, 0X40, 0X80, 0X00	
	;If you want to use the just 8 bits
.WORD	0X0001, 0X0002, 0X0004, 0X0008, 0X0010, 0X0020, 0X0040, 0X0080, 0X0100,	0X0200, 0X0400, 0X0800, 0X1000, 0X0000
	;If you want to use the full word
;This is a Shifting if you visualize data on portB with LEDs    
WELCOME:     
      .string "Hello, you are welcome!\r"  
      
MSJDIR:
    .string "Control: DIRECTION L-R\r"

MSJAB:
    .string "Control: DIRECTION A-B\r"
    
MSJE:
	.string "Control: STOP and EXPLOSION!\r"
    
MSJU:
    .string "Unrecognized command\r"
    
NUMEX:
    .string "Shots: "
    
MSJSTOP:
    .string "Control: STOP\r"
    
MSJEI:
    .string "Interruption: STOP and EXPLOSION!\r"
    
MSJSTATUS:
    .string "Working... Status:\r"
    
    
;..............................................................................
;Uninitialized variables in X-space in data memory
;..............................................................................

    .section .xbss, bss, xmemory
x_input: .space 2*SAMPLES        ;Allocating space (in bytes) to variable.



;..............................................................................
;Uninitialized variables in Y-space in data memory
;..............................................................................

    .section .ybss, bss, ymemory
y_input:  .space 2*SAMPLES




;..............................................................................
;Uninitialized variables in Near data memory (Lower 8Kb of RAM)
;..............................................................................

    .section .nbss, bss, near
var1:     .space 2               ;Example of allocating 1 word of space for
                                 ;variable "var1".
 ONES: .space 2
 TENS: .space 2
 HUNDRED: .space 2
 THOUSANDS: .space 2



;..............................................................................
;Code Section in Program Memory
;..............................................................................

.text                             ;Start of Code section
__reset:
    MOV #__SP_init, W15       ;Initalize the Stack Pointer
    MOV #__SPLIM_init, W0     ;Initialize the Stack Pointer Limit Register
    MOV W0, SPLIM
    NOP                       ;Add NOP to follow SPLIM initialization

    CALL _wreg_init           ;Call _wreg_init subroutine
                                  ;Optionally use RCALL instead of CALL




        ;<<insert more user code here>>

    CALL    CONF_PERIPHERALS
    ;CALL    CONF_UART1
    CALL    CONF_UART1TR
    CALL    CONF_INT0

    ;The program space address set contains 24 bits <23..0>
    ;TBLPAG takes the most significant byte of this set <22..16>
    ;the remaining is called Data Effective Address "EA" <15..0> which 
    ;is compatible with data space addressing.
    
    ; Setup the address pointer to program space
    ;PUSH    W0
    PUSH W2
    MOV	    #0x0FF,  W2
    MOV	    W2, PORTB
    POP	    W2
    MOV	    #49, W11
    MOV	    #49, W12
    MOV	    #48, W3
    
    ; Registos para los motores
    ;MOV	    #10,    W4
    CALL DELAY
    MOV     #tbloffset(WELCOME),W9     ; Initialize a text message pointer     
                                      ; Note using a TBLOFFSET operator     
                                      ; as we deal with data located in CODE memory.
    NOP
    CALL PRINT_MESSAGE
    
    
    CAR_ROUTINE:
	
	;MOV W11, W10
	;CALL __U1TXInterrupt
	CP W12, W11
	BRA NZ, PRINT_STATUS
	
	
	;MOV W10, U1TXREG
    
	CALL DELAY
	
    
    BRA CAR_ROUTINE
    
    
    COMPARE_EX:
	
	;PUSH W7
	MOV  #49, W7
	CP W8, W7
	BRA Z, SET_EX1
	
	MOV  #50, W7
	CP W8, W7
	BRA Z, SET_EX2    
	
	MOV  #51, W7	
	CP W8, W7
	BRA Z, SET_EX3
	
	MOV  #52, W7
	CP W8, W7
	BRA Z, SET_EX4
	;POP W7
	CALL DELAY
	RETURN
    
    SET_EX1:
	
	MOV #0x01FF, W7
	MOV W7, PORTB
	MOV #0, W8
	BRA COMPARE_EX
	
    SET_EX2:

	MOV #0x02FF, W7
	MOV W7, PORTB
	MOV #0, W8
	BRA COMPARE_EX
	
    SET_EX3:
	
	MOV #0x04FF, W7
	MOV W7, PORTB
	MOV #0, W8
	BRA COMPARE_EX
	
    SET_EX4:
	
	MOV #0x08FF, W7
	MOV W7, PORTB
	MOV #0, W8	
	BRA COMPARE_EX
    
    COMPARE_COMANDS:
	MOV #49, W13
	CP W13, W5
	BRA Z, PRINT_DIR1
	
	MOV #50, W13
	CP W13, W5
	BRA Z, PRINT_DIR2
	
	MOV #51, W13
	CP W13, W5
	BRA Z, PRINT_AB1
	
	MOV #52, W13
	CP W13, W5
	BRA Z, PRINT_AB2
	
	
	MOV #53, W13
	CP W13, W5
	BRA Z, PRINT_EXPLOTION
	
	MOV #54, W13
	CP W13, W5
	BRA Z, PRINT_STOP
	
	RETURN
	
    
    PRINT_MESSAGE:
	     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	
	RETURN
	
    PRINT_AB1:

	MOV     #tbloffset(MSJAB),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	MOV #0, W5
	
	PUSH W7
	MOV #0x0055, W7
	MOV W7, PORTB
	POP W7
	
	BRA COMPARE_COMANDS
	
    PRINT_AB2:

	MOV     #tbloffset(MSJAB),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	MOV #0, W5
	
	PUSH W7
	MOV #0x00AA, W7
	MOV W7, PORTB
	POP W7
	
	BRA COMPARE_COMANDS
	
    PRINT_STOP:

	MOV     #tbloffset(MSJSTOP),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	MOV #0, W5
	
	PUSH W7
	MOV #0x00FF, W7
	MOV W7, PORTB
	POP W7
	
	BRA COMPARE_COMANDS
	
    PRINT_DIR1:

	MOV     #tbloffset(MSJDIR),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	MOV #0, W5
	
	PUSH W7
	MOV #0x0077, W7
	MOV W7, PORTB
	POP W7
	
	BRA COMPARE_COMANDS
	
    PRINT_DIR2:

	MOV     #tbloffset(MSJDIR),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	MOV #0, W5
	
	PUSH W7
	MOV #0x00DD, W7
	MOV W7, PORTB
	POP W7
	
	BRA COMPARE_COMANDS
	
    PRINT_EXPLOTION:
	MOV     #tbloffset(MSJE),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	INC W3,W3
	MOV #0, W5
	MOV W3, W8
	
	CALL COMPARE_EX
	;PUSH W7
	;MOV #0x01FF, W7
	;MOV W7, PORTB
	;POP W7
	
	BRA COMPARE_COMANDS
	
    PRINT_EXP_INT:
	MOV     #tbloffset(MSJEI),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	CALL DELAY
	RETURN
    
    PRINT_STATUS:
	MOV W11, W12
	
	MOV     #tbloffset(MSJSTATUS),W9     
	CALL    _tx_string    
	
	MOV W11, W10 ; .
	CALL __U1TXInterrupt
	
	MOV #13, W10 ; CR
	CALL __U1TXInterrupt
	
	CALL DELAY
	
	MOV     #tbloffset(NUMEX),W9     
	CALL    _tx_string        ; Output a text string via UART1
	;MOV #87, W10 ;W
	;CALL __U1TXInterrupt
	MOV W3, W10 ; CR
	CALL __U1TXInterrupt
	
	MOV #13, W10 ; CR
	CALL __U1TXInterrupt
	
	CALL DELAY
	
	BRA CAR_ROUTINE
    
    DELAY:
	PUSH W0
	MOV	    #500, W0 ; MOV de prueba
	NOP
      ;MOV	    PORTD,  W0
      ; NOP
	CALL    DELAY_MS
	POP W0
	RETURN
    
    blink500:
    
    COM	    PORTB
    NOP
    PUSH W0
    MOV	    #500, W0 ; MOV de prueba
    NOP
  ; MOV	    PORTD,  W0
  ; NOP
    CALL    DELAY_MS
    POP W0
    BRA     blink500              ;Place holder for last line of executed code
    
    DELAY1MS:
	REPEAT #1838
	NOP
	RETURN
    
    DELAY_MS:   
	CALL DELAY1MS
	DEC W0, W0
	BRA NZ, DELAY_MS
	RETURN

    CONF_UART1:
	MOV #baudrate,W0 ; Set Baudrate
	MOV W0,U1BRG
	BSET IPC2,#U1RXIP2 ; Set UART RX interrupt priority
	BCLR IPC2,#U1RXIP1 ;
	BCLR IPC2,#U1RXIP0 ;
	CLR U1STA
	MOV #0x8800,W0 ; Enable UART for 8-bit data,
	; no parity, 1 STOP bit,
	; no wakeup
	MOV W0,U1MODE
	BSET IEC0,#U1RXIE ; Enable receive interrupts
	
	RETURN
	
	CONF_UART1TR:
	MOV #baudrate,W0 ; Set Baudrate
	MOV W0,U1BRG
	BSET IPC2,#U1TXIP2 ; Set UART TX interrupt priority
	BCLR IPC2,#U1TXIP1 ;
	BCLR IPC2,#U1TXIP0 ;
	BSET IPC2,#U1RXIP2 ; Set UART RX interrupt priority
	BCLR IPC2,#U1RXIP1 ;
	;BCLR IPC2,#U1RXIP0 ;
	BSET IPC2,#U1RXIP0 ;
	CLR U1STA
	MOV #0x8800,W0 ; Enable UART for 8-bit data,
	; no parity, 1 STOP bit,
	; no wakeup
	MOV W0,U1MODE
	BSET U1STA,#UTXEN ; Enable transmit
	BSET IEC0,#U1TXIE ; Enable transmit interrupts
	BSET IEC0,#U1RXIE ; Enable receive interrupts
	
	RETURN
	
	CONF_INT0:
	    BSET    INTCON1,	#NSTDIS

	    BCLR    IPC0,	#INT0IP0
	    BSET    IPC0,	#INT0IP1
	    BSET    IPC0,	#INT0IP2

	    BCLR    IFS0,	#INT0IF

	    BSET    INTCON2,	#INT0EP	    ;1 = Interrupt on negativa edge

	    BSET    IEC0,	#INT0IE

	    RETURN
	
    ITOA:
	
	DISI    #19
	REPEAT #17      ; Execute DIV.U 18 times
	DIV.U W2,W4
	
	MOV #0x30, W12
	ADD W1, W12, W1
	MOV W1, [W6++]  ;W6 debe apuntar a ONES
	MOV W0, W2
	CP0 W0
	BRA NZ, ITOA
	
	RETURN

;..............................................................................
;Subroutine: Initialization of W registers to 0x0000
;..............................................................................

_wreg_init:
    CLR W0
    MOV W0, W14
    REPEAT #12
    MOV W0, [++W14]
    CLR W14
    RETURN

	
;******************************************************************************
;	Same as a function in C	
;	VOID CONF_PERIPHERALS ( VOID )
;******************************************************************************		
CONF_PERIPHERALS:
    CLR         PORTA
    NOP
    CLR         LATA
    NOP
    SETM        TRISA		    ;PORTA AS INPUT
    NOP       			
    
    CLR         PORTB
    NOP
    CLR         LATB
    NOP
    CLR         TRISB		    ;PORTB AS OUTPUT
    NOP       			
    SETM	ADPCFG		    ;Disable analogic inputs
	
    CLR         PORTC
    NOP
    CLR         LATC
    NOP
    SETM        TRISC		    ;PORTC AS INPUT
    NOP       
	
    CLR         PORTD
    NOP
    CLR         LATD
    NOP 
    SETM        TRISD		    ;PORTD AS INPUT
    NOP

    CLR         PORTF
    NOP
    CLR         LATF
    NOP
    SETM        TRISF		    ;PORTF AS INPUT
    NOP       		
    
    RETURN    
    
    
;******************************************************************************
;    The following steps describe how to configure a source of interrupt:
;******************************************************************************		    
;1. Set the NSTDIS Control bit (INTCON1<15>) if nested interrupts are not desired.
;2. Select the user assigned priority level for the interrupt source by writing the control bits in
;the appropriate IPCx Control register. The priority level will depend on the specific
;application and type of interrupt source. If multiple priority levels are not desired, the IPCx
;register control bits for all enabled interrupt sources may be programmed to the same
;non-zero value.
;3. Clear the interrupt flag status bit associated with the peripheral in the associated IFSx
;Status register.
;4. Enable the interrupt source by setting the interrupt enable control bit associated with the
;source in the appropriate IECx Control register.
    
;    Note: At a device Reset, the IPC registers are initialized, such that all user interrupt
;sources are assigned to priority level 4.
    
    
    
;******************************************************************************
;    Interrupt Service Routine
;******************************************************************************
;The method that is used to declare an ISR and initialize the IVT with the correct vector address
;will depend on the programming language (i.e., C or assembler) and the language development
;tool suite that is used to develop the application. In general, the user must clear the interrupt flag
;in the appropriate IFSx register for the source of interrupt that the ISR handles. Otherwise, the
;ISR will be re-entered immediately after exiting the routine. If the ISR is coded in assembly
;language, it must be terminated using a RETFIE instruction to unstack the saved PC value, SRL
;value, and old CPU priority level.
    __U1RXInterrupt:
    PUSH    W0
    MOV U1RXREG, W0
    ;MOV W0, PORTB
    MOV W0, W11
    MOV W0, W5
    CALL COMPARE_COMANDS
    ;MOV	    #2000, W0 ; MOV de prueba
    ;NOP
    ;CALL    DELAY_MS
    
    POP	    W0
    
    BCLR    IFS0,	#U1RXIE	    ;the user must clear the interrupt flag

    RETFIE
    
    _tx_string: 
      ;mov #10, W13
      tblrdl.b        [W9++],W10       ; Read a next string byte to w0 and advance a string pointer w1     
      cp0.b   W10                  ; Check and exit if the byte equals to zero     
      bra     z,_rs232_tx_ret         ;   
      
      BRA   _tx_byte
      
    __U1TXInterrupt:
    
    ;BTSC    U1STA,#UTXBF
    cp0.b   W10                      ; Check and exit if the byte equals to zero
    bra     z,_rs232_tx_ret         ;
    _rs232_tx_byte:
       btsc    U1STA,#UTXBF            ; Check if UART1 TX buffer is empty
       bra     _rs232_tx_byte          ; Keep checking if not yet
       mov     W10,U1TXREG
       MOV	0x00, W10; Send a byte via UART1
       bra     __U1TXInterrupt        ; Loop until all non-zero bytes are transmitted
       
    _tx_byte:
       btsc    U1STA,#UTXBF            ; Check if UART1 TX buffer is empty
       bra     _tx_byte          ; Keep checking if not yet
       mov     W10,U1TXREG
       MOV	0x00, W10; Send a byte via UART1
       bra     _tx_string        ; Loop until all non-zero bytes are transmitted
       
    _rs232_tx_ret:
	;BCLR    IFS0,	#U1TXIE	    ;the user must clear the interrupt flag
	RETURN
    ;MOV	W10, U1TXREG

    ;RETFIE
    
    __INT0Interrupt:
	INC W3,W3
	MOV #53, W11
	CALL PRINT_EXP_INT
	MOV W3, W8
	
	;SECUENCIA DE STOP + DETONACION
	CALL COMPARE_EX
	
	CALL DELAY
	
	BCLR    IFS0,	#INT0IF	    ;the user must clear the interrupt flag

	RETFIE
    

;--------End of All Code Sections ---------------------------------------------   

.end                               ;End of program code in this file

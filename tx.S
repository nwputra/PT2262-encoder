#include	"attiny13.inc"

; R16 = gen purpose
; R17 = wdtcnt
; R18 = msgcnt
; R19 = Delay
; R20 = Delay Counter
; R21 = Delay Counter
; R22 = Element Delay Count
; R23 = Next Element Delay Count
;
#define		var			R16
#define		wdtcnt			R17
#define		msgcnt			R18
#define		delay			R19
#define		_di			R20
#define		_dj			R21
#define		elcnt			R22
#define		nxcnt			R23
;
; Non direct access register
;
; R15 = Event type
#define		event			R15


;
; Event type
;
#define		OPEN			0xFF
#define		SHUT			0xAA
#define		IR			0x3C


		.equ	FCPU,		4800000

		.equ    HBEAT,		4
		.equ    TX,		3

		.equ    DELAY,		10
		.equ    ELPER,		40


		.org	0x0000
		.global	init
init:		rjmp	Reset

		.org	0x0002
		rjmp	ExtINT0

		.org	0x0004
		rjmp	PCINT

		.org	0x0010
		rjmp	WDTINT

;
; Subroutine for delay 10uS at 4.8 MHz 
; 1 instruction cycle = 1/4.8 uS
; To get 10uS, need to spent 48 instruction cycle
; User set R19 as how many mS is requested
;
; Input			: delay = 10 micro Seconds delay
; Registers Used 	: delay, _di
Delay10uS:
		ldi	_di,(FCPU/400000)				; 1

DL_1:		dec	_di						; 1
		nop							; 1
		brne	DL_1						; 2/1
									; 12*4 + 1 = 49 cycle

		dec	delay						; Loop as requested by user
		brne	Delay10uS
		ret



; PCINT Handler
; No registers saved during interrupt
; Registers used : r0, r1, r2, r3, var, delay, _di, _dj, elcnt, nxcnt, r30, r31
;
PCINT:		in	var,PCMSK					;
		andi	var,~(PCINT0)					; disable PCINT0 while processing
		out	PCMSK,var					;

		in	var,PINB					; read pin status
		sbrs	var,0						; check PB0
		rjmp	Shut						; bit is clear, it is Shut

Open: 		ldi	var, OPEN					; Mark the event
		mov	event, var 
		rjmp	Done

Shut:		ldi	var, SHUT					; Mark the event
		mov	event, var 

Done:		cli							; no interrupts
		in      var,WDTCR					; procedure to change WDT
		ori     var,(1<<WDCE)|(1<<WDE)				; must write both as 1
		out     WDTCR,var					;
		ldi     var,(1<<WDTIE)|(1<<WDP2)|(1<<WDP0)		; WDT enabled as Interrupt at 0.5 Sec period
		out     WDTCR,var
		ldi	var,4						; count of WDT
		mov	wdtcnt,var					; save in wdtcnt

		sei
		reti



; INT0 Handler
; No registers saved during interrupt
; Registers used : r0, r1, r2, r3, var, delay, _di, _dj, elcnt, nxcnt, r30, r31
;
ExtINT0:	in	var,GIMSK					; disable INT0 during processing
		andi	var,~(1<<INT0)					; to avoid multiple interrupt
		out	GIFR,var					; clear pending INTF
		out	GIMSK,var					;

		ldi	var,IR						; Mark the event
		mov	event, var 

		cli							; no interrupts
		in      var,WDTCR					; procedure to change WDT
		ori     var,(1<<WDCE)|(1<<WDE)				; must write both as 1
		out     WDTCR,var					;
		ldi     var,(1<<WDTIE)|(1<<WDP2)|(1<<WDP0)		; WDT enabled as Interrupt at 0.5 Sec period
		out     WDTCR,var
		ldi	var,4						; count of WDT
		mov	wdtcnt,var					; save in wdtcnt

		sei
		reti



; WDTINT Handler
; No registers saved during interrupt
; Registers used : 
;
WDTINT:		cbi	PORTB,HBEAT					; Turn on HBEAT
		ldi	delay,25					; delay 25 mS
		rcall	DelayMS
		sbi	PORTB,HBEAT					; Turn off

		ldi	msgcnt,1
		rcall	PRsend						; Send preamble before sending bits
SendAgn:
		mov	var, event					; get the last event
		cpi	var, OPEN					; is it OPEN ?
		brne	notOpen	

		ldi	_di, lo8( opencode )				; Send OPEN Code
		rcall	CodeRead
		rjmp	SendCode

notOpen:	cpi	var, SHUT					; is it SHUT ?
		brne	notShut

		ldi	_di, lo8( shutcode )				; Send SHUT Code
		rcall	CodeRead
		rjmp	SendCode

notShut:	cpi	var, IR						; is it IR ?
		brne	Fin						; Not valid

		ldi	_di, lo8( key_code )				; Pointer to message to be sent
		rcall	CodeRead

SendCode:	rcall	PTsend						; Send the code
		dec	msgcnt
		brne	SendAgn

		dec	wdtcnt						; check count
		brne	ContSend					; Continue sending while count not zero

Fin:		cli							; no interrupts
		in      var,WDTCR					; procedure to change WDT
		ori     var,(1<<WDCE)|(1<<WDE)				; must write both as 1
		out     WDTCR,var					;
		ldi     var,(1<<WDP2)|(1<<WDP0)				; WDT disabled
		out     WDTCR,var

		in	var,GIMSK					;
		ori	var,(1<<INT0)					; enable INT
		out	GIMSK,var					;

		in	var,GIMSK					;
		ori	var,(1<<PCIE)					; enable PCINT
		out	GIMSK,var					;

		in	var,PCMSK					;
		ori	var,(PCINT0)					; enable PORTB0 pin change interrupt
		out	PCMSK,var					;

		sei

ContSend:	
		reti



;
; Subroutine for delay 1mS at 4.8 MHz
; 1 instruction cycle = 1/4.8 uS
; To get 1mS, need to spent 4800 instruction cycle
;
; Input			: delay = mili Seconds delay
; Registers Used 	: delay, _di, _dj
;
DelayMS:
		ldi	_di,(FCPU/800000)				; 1
DLM1:		ldi	_dj,200						; 1

DLM2:		dec	_dj						; 1
		nop							; 1
		brne	DLM2						; 2/1
									; 200*4 + 1 = 801 cycle
		dec	_di						; 1
		brne	DLM1						; 6*801 + 1 = 4801 cycle

		dec	delay						; Loop as requested by user
		wdr							; sanity OK
		brne	DelayMS
		ret



;
; Subroutine for sending Element
;
; Input			: elcnt = Number of element
; Registers used 	: elcnt, delay, _di, _dj
;
ElDelay:	ldi	delay,ELPER
		rcall	Delay10uS

		dec	elcnt
		brne	ElDelay
		ret


;
; Subroutine for sending preamble
; Consisting 32 bit off 50% dutycycle stream
; Returns : None
;
; Input			: none
; Registers used 	: r3, var, delay, _di, _dj, elcnt, nxcnt
;
PRsend:		ldi	var,32						; setup 32 bit shift
		mov	r3,var						;

NextPre:	or	r3,r3
		breq	EndPre

		wdr							; sanity OK
	 	sbi	PORTB,TX					; Turn on TX
		ldi	elcnt,1						; 1 element delay
		rcall	ElDelay						; 
		cbi	PORTB,TX					; TX off
		ldi	elcnt,1						; 1 element delay
		rcall	ElDelay						; 

		dec	r3
		rjmp	NextPre

EndPre:		ret



;
; Subroutine for sending the code
; Code is passed using Z register
; Returns : None
;
; Input			: r0, r1, r2 = pointer to message to be sent
; Registers used 	: r3, var, delay, _di, _dj, elcnt, nxcnt
;
PTsend:		ldi	var,24						; setup 24 bit shift
		mov	r3,var						;

NextShift:	or	r3,r3
		breq	EndBits

		wdr							; sanity OK
		clc							; shift the MSB to Carry
		rol	r2
		rol	r1
		rol	r0

		brcs	PTSend1						; Send Logical 1

PTSend0:	ldi	elcnt,1						; 1 element delay
		ldi	nxcnt,3						; followed by 3 element delay
		rjmp	SendEl

PTSend1:	ldi	elcnt,3						; 3 element delay
		ldi	nxcnt,1						; followed by 1 element delay

SendEl: 	sbi	PORTB,TX					; Turn on TX
		rcall	ElDelay						; 
		cbi	PORTB,TX					; TX off
		mov	elcnt,nxcnt					; 
		rcall	ElDelay						; 

		dec	r3
		rjmp	NextShift

EndBits:	ldi	elcnt,1						; Send SYNC bit
		sbi	PORTB,TX					;
		rcall	ElDelay						; 
		cbi	PORTB,TX					;
		ldi	elcnt,31					; delay is 31 element
		rcall	ElDelay						; 
		ret



; EEread
;
; Read EEPROM which address defined in EEARL
; Returns 		: _dj contais the EEPROM data
; 
; Input			: _di = pointer to address to be read
; Registers used 	: _dj
;
EEread:		out	EEARL, _di					; Set EEPROM address
		sbic	EECR,EEPE					; wait until idle
		rjmp	EEread						;

		sbi	EECR,EERE					; Start EEPROM read

		in	_dj,EEDR					; Read the EEPROM data
		ret




; CodeRead
;
; Read 3 bytes from EEPROM which address defined in _di
; Returns 		: r0, r1, r2 contais the EEPROM data [Code to be sent]
;			: _di and _dj changed
; 
; Input			: _di = pointer to first byte of EEPROM address to be read
; Registers used 	: _di, _dj
;
CodeRead:	rcall	EEread
		mov	r0, _dj 
		inc	_di
		rcall	EEread
		mov	r1, _dj
		inc	_di
		rcall	EEread
		mov	r2, _dj
		ret



; Reset goes here ...
; - Setup hardware IO PORT
; - Send one flash on HBEAT LED
; - Check whether WDT triggered this reset
;
;
Reset:		ldi	r28,lo8( RAMEND )				; Top of RAM
		out	SPL,r28						; Initialize Stack Pointer

		ldi	var,(1<<HBEAT)|0x02|0x01			; Set PullUps for inputs (PB1, PB0)
		out	PORTB,var					; HBEAT is active low, turn it OFF
		ldi	var,((1<<TX) | (1<<HBEAT))			; PORTB Bit 4..3 as output
		out	DDRB,var

		in	var,MCUSR					; 
		sbrs	var,WDRF					; Watchdog reset ?
		rjmp	CheckEXT					; No, continue checking ...

WDTReset:	andi	var,~(1<<WDRF)					; Clear WDRF
		out	MCUSR,var					; 
									; Fall through

CheckEXT:	sbrs	var,EXTRF					; External Reset ?
		rjmp	CheckPOR					; No, continue checking ...

EXTReset:	andi	var,~(1<<EXTRF)					; Clear EXTRF
		out	MCUSR,var					;
									; Fall through

CheckPOR:	sbrs	var,PORF					; Power On Reset ?
		rjmp	CheckBOR					; No, continue with last one ...

PORReset:	andi	var,~(1<<PORF)					; Clear PORF
		out	MCUSR,var					;


		ldi	_di,0x00					; Read address 0x00 of EEPROM
		rcall	EEread						; Start EEPROM read
		out	OSCCAL,_dj					; Put OSCCAL value
									; Fall through

CheckBOR:	sbrs	var,BORF					; Brownout Reset ?
		rjmp	Main						; No, Just continue ...

BORReset:	andi	var,~(1<<BORF)					; Clear BORF
		out	MCUSR,var					;
									; Fall through

Main:		cbi	PORTB,HBEAT					; Turn on HBEAT
		ldi	delay,25					; delay 25 mS
		rcall	DelayMS
		sbi	PORTB,HBEAT					; Turn off

		eor	var,var
		out	MCUSR,var					; clear all MCUSR
		ldi	wdtcnt,DELAY					; Initialize parameters 

		cli							; no interrupts
		ldi	var,(1<<SM1)					; Set Power-down sleep mode,
		out	MCUCR,var					; and Enable Level interrupt

		in	var,GIMSK					;
		ori	var,(1<<INT0)					; enable INT
		out	GIFR,var					; clear pending INTF
		out	GIMSK,var					;


		in	var,PCMSK					;
		ori	var,(PCINT0)					; enable PCINT0
		out	PCMSK,var					;

		in	var,GIMSK					;
		ori	var,(1<<PCIE)					; enable PCINT
		out	GIFR,var					; clear pending PCIF
		out	GIMSK,var					;

		sei							; enable interrupts

		in	var,MCUCR					; enable sleep mode
		ori	var,(1<<SE)					;
		out	MCUCR,var					;

Loop:		sleep							; go to sleep
		rjmp	Loop						; loop forever


		.section .eeprom
		.org	0x00		
osccal:	 	.byte			0x54
dummy:	 	.byte			0xFF
key_code: 	.byte			0x23, 0x74, 0x7F
shutcode: 	.byte			0x23, 0x74, 0x80
opencode: 	.byte			0x23, 0x74, 0x8F




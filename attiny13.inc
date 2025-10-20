
		.equ	SPL,		0x3D
		.equ	GIMSK,		0x3B
		.equ	GIFR,		0x3A
		.equ	TIMSK0,		0x39

		.equ	OCR0A,		0x36
		.equ	MCUCR,		0x35
		.equ	MCUSR,		0x34
		.equ	TCCR0B,		0x33
		.equ	TCNT0,		0x32
		.equ	OSCCAL,		0x31

		.equ	TCCR0A,		0x2F
		.equ	OCR0B,		0x29
		.equ	CLKPR,		0x26
		.equ	WDTCR,		0x21

		.equ	EEARL,		0x1E
		.equ	EEDR,		0x1D
		.equ	EECR,		0x1C

		.equ	PORTB,		0x18
		.equ	DDRB,		0x17
		.equ	PINB,		0x16
		.equ	PCMSK,		0x15

		.equ	ACSR,		0x08
		.equ	ADMUX,		0x07
		.equ	ADCSRA,		0x06
		.equ	ADCH,		0x05
		.equ	ADCL,		0x04


		.equ	WDRF,		3
		.equ	BORF,		2
		.equ	EXTRF,		1
		.equ	PORF,		0

		.equ	PUD,		6
		.equ	SE,		5
		.equ	SM1,		4
		.equ	SM0,		3
		.equ	ISC01,		1
		.equ	ISC00,		0

		.equ	INTF0,		6
		.equ	PCIF,		5

		.equ	INT0,		6
		.equ	PCIE,		5

		.equ	PCINT0,		0x01
		.equ	PCINT1,		0x02
		.equ	PCINT2,		0x04
		.equ	PCINT3,		0x08
		.equ	PCINT4,		0x10
		.equ	PCINT5,		0x20

		.equ	WDTIF,		7
		.equ	WDTIE,		6
		.equ	WDP3,		5
		.equ	WDCE,		4
		.equ	WDE,		3
		.equ	WDP2,		2
		.equ	WDP1,		1
		.equ	WDP0,		0

		.equ	EERE,		0
		.equ	EEPE,		1
		.equ	EEMPE,		2
		.equ	EERIE,		3
		.equ	EEPM0,		4
		.equ	EEPM1,		5

		.equ	HBEAT,		3
		.equ	TX,		4

		.equ	DELAY,		10
		.equ	ELPER,		50

		.equ	RAMEND,		0x009F

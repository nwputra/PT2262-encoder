MAKE	= /usr/bin/make
F_CPU   = 4800000

# ATTINY13
# Fuse High all are unprogrammed
# Fuse Low :
# 7 - SPIEN	: SPI Programming 	= 0
# 6 - EESAVE	: Preserve EEPROM	= 1
# 5 - WDTON	: WDT always on		= 1
# 4 - CKDIV8	: Divide clock by 8	= 1
# 3 - SUT1	: Start up		= 1
# 2 - SUT0	: Start up		= 1
# 1 - CKSEL1	: Clock select		= 0
# 0 - CKSEL0	: Clock select		= 1
#
# Use Internal clock 4.8 MHz
#
FUSE_H=0xFF
FUSE_L=0x7D

DEVICE=attiny13
CFLAGS= -g -Os -Wall -mcall-prologues -mmcu=$(DEVICE)
CPU=t13

OBJ2HEX	=	/usr/bin/avr-objcopy 
PROG	=	/usr/bin/avrdude 
TARGET	=	tx
VPATH	=	tx
SS	=	tx
OBJS	=	tx.o 
CC	= 	avr-gcc -Wall -Os -DF_CPU=$(F_CPU) $(CFLAGS)
LINK	=	avr-ld -e init
AVRDUDE	=	$(PROG) -c usbasp -P usb -p $(CPU) -B8

.PHONY:	$(SS)

all			:	$(TARGET).hex
				
$(SS)			:
				$(MAKE) -C $@
clean 			:
				rm -f *.hex *.obj *.elf *.o *.eep
				rm -f */*.o

.S.o			:
				$(CC) -x assembler-with-cpp -c $< -o $@

$(TARGET).hex		:	$(TARGET).elf
				$(OBJ2HEX) -R .eeprom -O ihex $< $@
				avr-objcopy -j .eeprom --set-section-flags=.eeprom="alloc,load" --change-section-lma .eeprom=0 -O ihex $(TARGET).elf  $(TARGET).eep
				avr-size $(TARGET).hex


$(TARGET).elf		:	$(OBJS)
				$(LINK) -o $(TARGET).elf $(OBJS)

program 		: 	$(TARGET).hex
				$(AVRDUDE)
				$(AVRDUDE) -U flash:w:$(TARGET).hex:i 
				$(AVRDUDE) -U flash:v:$(TARGET).hex:i 

eeprom			:	$(TARGET).o
				$(AVRDUDE) -U eeprom:w:$(TARGET).eep:i 
				$(AVRDUDE) -U eeprom:v:$(TARGET).eep:i 

fuse:
	@[ "$(FUSE_H)" != "" -a "$(FUSE_L)" != "" ] || \
		{ echo "*** Edit Makefile and choose values for FUSE_L and FUSE_H!"; exit 1; }
	$(AVRDUDE) -U hfuse:w:$(FUSE_H):m -U lfuse:w:$(FUSE_L):m



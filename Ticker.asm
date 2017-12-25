 #include P18F452.inc

 cblock 0x000
  tickDelayCounter
  audioDelayCounter
  audioDelay
  dacByte
  spiByte
  trash
  zero
 endc
 
 sineWaveAddress equ 0x50
 
 
; MACROS
movlf	macro literal, register
	movlw literal
	movwf register
endm

org 0x0000
goto Init
org 0x0008
org 0x18
 
 ; MAIN
 
; motor pins in order: E2 B1 B0 C2 
Init:
    nop
    movlw	B'10001110'		; Default is analog I/O PORTA & PORTE pins
    movwf	ADCON1
    
    ; setup audio pin to output
    bcf TRISC, 1
    
    ; setup motor pins to outputs
    bcf TRISE, 2
    bcf TRISB, 1
    bcf TRISB, 0
    bcf TRISC, 2
    
    ;Load sine wave
    movlf 0x00, FSR0H
    movlf sineWaveAddress, FSR0L
    movlf D'128', POSTINC0
    movlf D'167', POSTINC0
    movlf D'203', POSTINC0
    movlf D'231', POSTINC0
    movlf D'249', POSTINC0
    movlf D'255', POSTINC0
    movlf D'249', POSTINC0
    movlf D'231', POSTINC0
    movlf D'203', POSTINC0
    movlf D'167', POSTINC0
    movlf D'128', POSTINC0
    movlf D'89', POSTINC0
    movlf D'53', POSTINC0
    movlf D'25', POSTINC0
    movlf D'7', POSTINC0
    movlf D'1', POSTINC0
    movlf D'7', POSTINC0
    movlf D'25', POSTINC0
    movlf D'53', POSTINC0
    movlf D'89', POSTINC0
    movlf D'128', POSTINC0
    
PreMainLoopSetup:
    movlf 0xff, audioDelay
    
MainLoop:
    decfsz audioDelayCounter
    bra AudioDelaySkip
    movff audioDelay, audioDelayCounter
    btg PORTC, 1
    bra AudioDelayContinue
    AudioDelaySkip:
    nop
    nop
    bra AudioDelayContinue
    
    AudioDelayContinue:
    
    
    
    movlf D'30', tickDelayCounter
    TickDelayLoop:
    decfsz tickDelayCounter
    bra TickDelayLoop
    bra MainLoop
    
    
    
UpdateDAC: ; Sends the data in DACByte to the DAC
    bcf PORTC,RC0 ; Clear PORTC,RC0 to select DAC
    movlf 0x21, spiByte ; Move 0x21 to BYTE (select DAC-A) (0x22 selects DAC-B)
    rcall SPItransfer ; Call SPItransfer subroutine
    movff dacByte, spiByte ; The value Data is copied to BYTE
    rcall SPItransfer ; Call SPItransfer subroutine
    bsf PORTC,RC0 ; Set RC0 to release DAC
    return
    
SPItransfer:
    bcf PIR1,SSPIF ; Clear PIR1,SSPIF to ready for transfer.
    movff spiByte,SSPBUF ; Initiates write when anything is placed in SSPBUF. Byte‡ SSPBUF
Wait_SPI: ; Wait until transfer is finished.
    btfss PIR1,SSPIF ; Testaa lippua
    bra Wait_SPI ; Ei asettunut, hypp‰‰ Wait_SPI
    movff SSPBUF,trash
    return
    
end
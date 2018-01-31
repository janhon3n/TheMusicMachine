 #include P18F452.inc

 cblock 0x000
  tickDelayCounter
  audioDelayCounter
  audioDelay
  motorDelayCounterL
  motorDelayCounterH
  motorDelayL
  motorDelayH
  motorState
  dacByte
  spiByte
  trash
  zero
 endc
 
sineWaveAddress equ 0x50
noteListAddress equ 0x70
 
noteDelay  equ     65536-1000+12+2
 
 
; MACROS
movlf	macro literal, register
	movlw literal
	movwf register
endm
	
movbb	macro sourceRegister, sourceBit, destinationRegister, destinationBit
	BTFSC sourceRegister, sourceBit
	bsf destinationRegister, destinationBit ; source bit = 1
	BTFSS sourceRegister, sourceBit
	bcf destinationRegister, destinationBit ; source bit = 0
endm
	
	

org 0x0000 
goto Init
org 0x0008
org 0x18
goto Timer0Interrupt
 
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
    movlf B'11001100', motorState
    ; setup motor delay
    movlf 0x05, motorDelayH
    movlf 0xD0, motorDelayL
    
    
    ; setup timer¥
    movlw  high  noteDelay
    movwf  TMR0H
    movlw  low  noteDelay
    movwf  TMR0L
    movlw	B'10000111'
    movwf	T0CON			;Set up Timer0
	
    bcf	INTCON,TMR0IF	; nollaa keskeytyslippu
    bsf	INTCON,TMR0IE	; salli TMR0 keskeytykset
    bsf	INTCON,GIE	; salli keskeytykset
    
    
    ; Load noteDelays
    movlf 0x00, FSR1H
    movlf noteListAddress, FSR1L
    movlf D'252', POSTINC1
    movlf D'225', POSTINC1
    movlf D'200', POSTINC1
    movlf D'189', POSTINC1
    movlf D'168', POSTINC1
    movlf D'150', POSTINC1
    movlf D'133', POSTINC1
    movlf D'126', POSTINC1
    
    movlf noteListAddress, FSR1L
    
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
    movlf D'252', audioDelay
    
MainLoop:
    
	;TODO if button then skip to delay
	
    ; UPDATE AUDIO
    decfsz audioDelayCounter
    bra AudioDelaySkip
    movff audioDelay, audioDelayCounter
    btg PORTC, 1
    bra AudioDelayContinue
    AudioDelaySkip:
    nop
    nop
    nop
    bra AudioDelayContinue
    
    AudioDelayContinue:
    
    
    
    ; UPDATE MOTOR
    decfsz motorDelayCounterL
    bra MotorDelaySkipLow
    movff motorDelayL, motorDelayCounterL
    decfsz motorDelayCounterH
    bra MotorDelaySkipHigh
    movff motorDelayH, motorDelayCounterH
    ; aika vaihtaa askelmaa
    rcall ChangeMotorStep
        
    
    MotorDelaySkipLow:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    bra MotorDelayContinue
    
    MotorDelaySkipHigh:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    bra MotorDelayContinue
    
    MotorDelayContinue:
    
    movlf D'10', tickDelayCounter
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
    
    
ChangeMotorStep:
    RRNCF motorState
    movbb motorState, 0, PORTE, 2
    movbb motorState, 1, PORTB, 1
    movbb motorState, 2, PORTB, 0
    movbb motorState, 3, PORTC, 2
    return
    
    
    
Timer0Interrupt:
	bcf	INTCON,TMR0IF		; nollaa keskeytyslippu
	
	; vaihda audioDelay
	movf POSTINC1, w
	TSTFSZ WREG ; jos ladattu arvo = 0, siirry takaisen ensimm‰iseen muistiosoitteeseen
	bra SkipNoteAddressReset
	movlf noteListAddress, FSR1L
	movf POSTINC1, w
	SkipNoteAddressReset:
	movwf audioDelay
	
    movlw  high  noteDelay
	movwf  TMR0H
 	movlw  low  noteDelay
	movwf  TMR0L
 	retfie	FAST
    
    
end
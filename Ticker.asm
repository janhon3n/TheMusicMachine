 #include P18F452.inc

 cblock 0x000
  tickDelayCounter
  audioDelayCounter
  audioDelay
  buttonState
  dacByte
  spiByte
  trash
  zero
 endc
 
noteListAddress equ 0x20
 
noteDelay  equ  D'26457'
  
buttonPin equ 3
buttonRegister equ PORTD

 
ledPin equ 2
ledRegister equ PORTC
ledPin2 equ 0
ledRegister2 equ PORTB
 
 
; MACROS
movlf	macro literal, register
	movlw literal
	movwf register
    endm


    org 0x0000 
    goto Init
    org 0x0008
    org 0x0018
    goto Timer0Interrupt

 ; MAIN
 
Init:
    nop
    movlw	B'10001110'		; Default is analog I/O PORTA & PORTE pins
    movwf	ADCON1
    
    ; setup audio pin to output
    bcf TRISC, 1
    
    ; setup button pin to input
    bsf TRISD, 3
    
    ; setup led pins to output
    bcf TRISC, 2
    bcf TRISB, 0
    
    ; setup timer
    movlw  high  noteDelay
    movwf  TMR0H
    movlw  low  noteDelay
    movwf  TMR0L
    movlw   B'10000100'
    movwf   T0CON			;Set up Timer0
	
    bcf	INTCON,TMR0IF	; nollaa keskeytyslippu
    bsf	INTCON,TMR0IE	; salli TMR0 keskeytykset
    bsf	INTCON,GIE	; salli keskeytykset    
    
    ; Load noteDelays
    movlf 0x00, FSR1H
    movlf noteListAddress, FSR1L
    movlf D'252', POSTINC1
    movlf D'200', POSTINC1
    movlf D'133', POSTINC1
    movlf D'150', POSTINC1
    movlf D'252', POSTINC1
    movlf D'200', POSTINC1
    movlf D'133', POSTINC1
    movlf D'150', POSTINC1
    movlf D'225', POSTINC1
    movlf D'189', POSTINC1
    movlf D'133', POSTINC1
    movlf D'150', POSTINC1
    movlf D'225', POSTINC1
    movlf D'189', POSTINC1
    movlf D'133', POSTINC1
    movlf D'150', POSTINC1
    
    movlf noteListAddress, FSR1L
    
PreMainLoopSetup:
    movlf D'252', audioDelay
    bsf ledRegister, ledPin
    
MainLoop:
    
    ; if button then skip to delay
    btfsc buttonRegister, buttonPin
    bra ButtonSkip
    bcf buttonState, 0
    bcf PORTC, 1
    bra AudioDelayContinue
   
    
ButtonSkip:
    bsf buttonState, 0
    
    
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
    
    
    movlf D'10', tickDelayCounter
TickDelayLoop:
    decfsz tickDelayCounter
    bra TickDelayLoop
    bra MainLoop
    
      
    
Timer0Interrupt:
	bcf	INTCON,TMR0IF		; nollaa keskeytyslippu
	
	; vaihda audioDelay
	movf POSTINC1, w
	TSTFSZ WREG ; jos ladattu arvo = 0, siirry takaisen ensimm�iseen muistiosoitteeseen
	bra SkipNoteAddressReset
	movlf noteListAddress, FSR1L
	movf POSTINC1, w
	
SkipNoteAddressReset:
	movwf audioDelay
	btfss buttonState, 0
	bra DontUpdateLed
	bra UpdateLed
	
DontUpdateLed:
	bcf ledRegister, ledPin
	bcf ledRegister2, ledPin2
        bra UpdateLedEnd
    
UpdateLed:
	btg ledRegister, ledPin
	bcf ledRegister2, ledPin2
	btfss ledRegister, ledPin
	bsf ledRegister2, ledPin2
	bra UpdateLedEnd
	
UpdateLedEnd:
	
	movlw  high  noteDelay
	movwf  TMR0H
 	movlw  low  noteDelay
	movwf  TMR0L
 	retfie	FAST
    
    
end
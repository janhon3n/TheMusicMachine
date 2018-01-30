 #include P18F452.inc

 cblock 0x000
  motorDelayL
  motorDelayH
  trash
  zero
 endc
 
 sineWaveAddress equ 0x30
 
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
    
    bcf TRISE, 2
    bcf TRISB, 1
    bcf TRISB, 0
    bcf TRISC, 2
    
MainLoop:
    ; motor pins in order: E2 B1 B0 C2 
    bcf PORTC, 2
    bsf PORTB, 1
    rcall MotorDelay
    bcf PORTE, 2
    bsf PORTB, 0
    rcall MotorDelay
    bcf PORTB, 1
    bsf PORTC, 2
    rcall MotorDelay
    bcf PORTB, 0
    bsf PORTE, 2
    rcall MotorDelay
    bra MainLoop
    
MotorDelay:
    movlf 0x10, motorDelayH
    movlf 0xff, motorDelayL
    MotorDelayLoop:
    DECFSZ motorDelayL
    bra MotorDelayLoop
    movlf 0xff, motorDelayL
    DECFSZ motorDelayH
    bra MotorDelayLoop
    return
end
 #include P18F452.inc

 cblock 0x000
  signalPeriodDelayHighCounter
  signalPeriodDelayLowCounter
  signalPeriodDelayLowCounterSave
  signalPeriodDelayHigh
  signalPeriodDelayLow
  testRegister
  BYTE
  trash
 endc

 tmr0Delay equ 65535 - 30000 + 2 + 8
 testLedPort equ PORTA
 testDelay equ 0x000f ;0x0fff
 testLed equ 1
 testLed2 equ 2
 outputPort equ PORTB
 output equ 1
 
 
; MACROS
movlf	macro literal, register
	movlw literal
	movwf register
endm

org 0x0000
goto Init
org 0x0008
goto Timer0Event
org 0x18
 
 ; MAIN
 
Init:
    movlw high testDelay
    movwf signalPeriodDelayHigh
    movlw low testDelay
    movwf signalPeriodDelayLow
    
    movlw	B'10001110'		; Default is analog I/O PORTA & PORTE pins
    movwf	ADCON1
    
    ; D/A converter setup
    movlf B'11000010', TRISC
    movlf 0x00 SSPSTAT
    movlf 0x32 SSPCON1
    movlf 0xff, testRegister
   
    bcf TRISA, testLed ; set testLed as output
    bcf TRISA, testLed2 ; set testLed as output
    bcf TRISB, output
    
    bsf testLedPort, testLed
    bsf testLedPort, testLed2
    
    movlf B'10000111', T0CON
    
    bcf	INTCON,TMR0IF	; nollaa keskeytyslippu
    bsf	INTCON,TMR0IE	; salli TMR0 keskeytykset
    bsf	INTCON,GIE	; salli keskeytykset
    
    movlw high tmr0Delay
    movwf TMR0H
    movlw low tmr0Delay
    movwf TMR0L
    

    
MainLoop:
    btg outputPort, output
    btg testLedPort, testLed2
    
    bcf PORTC,RC0 ; Clear PORTC,RC0 to select DAC
    movlf 0x21, BYTE ; Move 0x21 to BYTE (select DAC-A) (0x22 selects DAC-B)
    rcall SPItransfer ; Call SPItransfer subroutine
    movff 0xa0, BYTE ; The value Data is copied to BYTE
    rcall SPItransfer ; Call SPItransfer subroutine
    bsf PORTC,RC0 ; Set RC0 to release DAC
    
    decf testRegister
    movlw 0x00
    cpfsgt testRegister
    movlf 0xff, testRegister
    
    call SignalPeriodDelay
    bra MainLoop
    
    
SignalPeriodDelay:
    movff signalPeriodDelayHigh, signalPeriodDelayHighCounter
    movff signalPeriodDelayLow, signalPeriodDelayLowCounter
    movff signalPeriodDelayLow, signalPeriodDelayLowCounterSave
    SignalPeriodDelayLoop:
    decfsz signalPeriodDelayLowCounter
    bra SignalPeriodDelayLoop
    movff signalPeriodDelayLowCounterSave, signalPeriodDelayLowCounter
    decfsz signalPeriodDelayHighCounter
    bra SignalPeriodDelayLoop
    return
    
    
    ;;;;;;; SPItransfer subroutine
SPItransfer:
    bcf PIR1,SSPIF ; Clear PIR1,SSPIF to ready for transfer.
    movff BYTE,SSPBUF ; Initiates write when anything is placed in SSPBUF. Byte‡ SSPBUF
Wait_SPI: ; Wait until transfer is finished.
    btfss PIR1,SSPIF ; Testaa lippua
    bra Wait_SPI ; Ei asettunut, hypp‰‰ Wait_SPI
    movff SSPBUF,trash
    return
    
    
Timer0Event:
    btg testLedPort, testLed
    ;incf signalPeriodDelayHigh
    
    movlw high tmr0Delay
    movwf TMR0H
    movlw low tmr0Delay
    movwf TMR0L
    
    bcf	INTCON,TMR0IF		; nollaa keskeytyslippu
    
    retfie FAST
end
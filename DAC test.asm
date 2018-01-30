 #include P18F452.inc

 cblock 0x000
  DACByte
  SPIByte
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
 
Init:
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

    nop
    nop
    
    
    
    ; D/A converter setup
    movlf B'11000010', TRISC
    movlf 0x00, SSPSTAT
    movlf 0x32, SSPCON1
    movlf 0x00, DACByte
    
    nop
    nop
    nop
    nop
    
    movlf 0x00, FSR0H
    movlf sineWaveAddress, FSR0L
    
    
MainLoop:
    
    movf POSTINC0, w
    TSTFSZ WREG ; jos ladattu arvo = 0, siirry takaisen ensimm‰iseen muistiosoitteeseen
    bra SkipAddressReset
    movlf sineWaveAddress, FSR0L
    movf POSTINC0, w
    SkipAddressReset:
    movwf DACByte
    rcall UpdateDAC

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
    
    bra MainLoop    
    
    
    
UpdateDAC: ; Sends the data in DACByte to the DAC
    bcf PORTC,RC0 ; Clear PORTC,RC0 to select DAC
    movlf 0x21, SPIByte ; Move 0x21 to BYTE (select DAC-A) (0x22 selects DAC-B)
    rcall SPItransfer ; Call SPItransfer subroutine
    movff DACByte, SPIByte ; The value Data is copied to BYTE
    rcall SPItransfer ; Call SPItransfer subroutine
    bsf PORTC,RC0 ; Set RC0 to release DAC
    return
    
SPItransfer:
    bcf PIR1,SSPIF ; Clear PIR1,SSPIF to ready for transfer.
    movff SPIByte,SSPBUF ; Initiates write when anything is placed in SSPBUF. Byte‡ SSPBUF
Wait_SPI: ; Wait until transfer is finished.
    btfss PIR1,SSPIF ; Testaa lippua
    bra Wait_SPI ; Ei asettunut, hypp‰‰ Wait_SPI
    movff SSPBUF,trash
    return
end
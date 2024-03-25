;---------------------
; Main Program
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
    
    ORG          0                ;Reset vector
    GOTO        Ports

    ORG          0020H           ; Begin assembly at 0020H
 
Ports: 
    BANKSEL	PORTB
    CLRF	PORTB
    BANKSEL	LATB ; Data Latch
    CLRF	LATB 
    BANKSEL	ANSELB 
    CLRF	ANSELB ; digital I/O
    BANKSEL	TRISB 
    CLRF   TRISB
      
   BANKSEL	PORTD
    CLRF	PORTD
    BANKSEL	LATD ; Data Latch
    CLRF	LATD
    BANKSEL	ANSELD 
    CLRF	ANSELD ; digital I/O
    BANKSEL	TRISD 
    MOVLW	0b11000000 ;Set RD0 & RD1 as inputs
    MOVWF	TRISD

Start:
    MOVLW      0x00 ; setting the upper table pointer at 0x00
    MOVWF      TBLPTRU 
    MOVLW      0x01  ; setting the higher table pointer at 0x01
    MOVWF      TBLPTRH
    MOVLW      0x60  ; setting the higher table pointer at 0x60
    MOVWF      TBLPTRL 
 
    ORG 0x160 ;where display numbers for table pointers is located
SEG_TABLE: 
	    db  0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D ;0-5 in display
	    db  0x7D, 0x07, 0x7F, 0x6F,0x77 ; 6-10 in display
	    db  0x7C, 0x39, 0x5E, 0x79 ; B-E in display
	    db 0x71 ; F (15) in display
	    
	    


;---------------------
; Initialization
;---------------------
#include "C:\Users\lunaf\MPLABXProjects\practice_led.X\AssemblyConfig.inc"
#include <xc.inc>
;---------------------
; Definitions
;---------------------  
#define button_1  PORTB, 0
#define button_2  PORTB, 1
;---------------------
; Program Constants
;---------------------
INNER_LOOP       EQU 0xFF
INNER_LOOP_REG   EQU 0x20
INNER_LOOP_2     EQU 0xFF
INNER_LOOP_2_REG EQU 0x24
;---------------------
; Main Program
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
   
    ORG          00               ;Reset vector
    GOTO        Ports

    ORG          0020H           ; Begin assembly at 0020H
   	
Ports:;initialize ports for inputs/outputs
    BANKSEL PORTD
    CLRF PORTD
    BANKSEL LATD
    CLRF LATD
    BANKSEL ANSELD
    CLRF ANSELD
    BANKSEL TRISD
    CLRF TRISD ;set PORTD to outputs
   
    BANKSEL PORTB
    CLRF PORTB
    BANKSEL LATB
    CLRF LATB
    BANKSEL ANSELB
    CLRF ANSELB
    BANKSEL TRISB
    MOVLW 0b00000011 ;set RB0 & RD1 as inputs
    MOVWF TRISB  
    
regs_setup: ;setting up regs
    MOVLW      0x00 ;setting the upper table pointer at 0x00
    MOVWF      TBLPTRU
    MOVLW      0x01 ;setting the higher table pointer at 0x01
    MOVWF      TBLPTRH   
check_reset: ;always show zero when no pushes/both push 				    
    MOVLW   0x60 ;also a part of reg setup (setting lower pointer to 0x60)	    
    MOVWF   TBLPTRL 
    TBLRD*  ;reading from table latch which is pointed at 0x60 (0x3F)
    MOVFF   TABLAT, PORTD ;displaying 0
    RCALL    delay ;rough 1 sec delay        
button_setup: 			    
    BTFSC   button_2 ;if not pressed, skip
    GOTO    button_2_pushed ;increments
    BTFSC   button_1 ;if not pressed, skip
    GOTO    button_1_pushed ;decrements
    GOTO    button_setup ;costantly checking if a button is pushed
    
reset_neg_regs: ;positioned there for convienence
    MOVLW      0x00 ;setting the upper table pointer at 0x00
    MOVWF      TBLPTRU
    MOVLW      0x01  ;setting the higher table pointer at 0x01
    MOVWF      TBLPTRH
    MOVLW      0x6F  ;setting the higher table pointer at 0x6F
    MOVWF      TBLPTRL
    
button_2_pushed:
    BTFSC   button_1 ; checks if both buttons are pressed		    
    GOTO    check_reset	;if button 1 now pressed too, got to check_reset
    RCALL   display ; function that diplays the value
    RCALL   check_table_decr ;checks seg table pointers
    RCALL   delay ;roughly 1 sec delay
    DECF    TBLPTRL, F ;decrements from table pointer of seg table
    GOTO    button_2_pushed ;loops decrementation
 
check_table_decr:;checks seg table pointer
    MOVLW   0x5F ;pointed at before our seg table		    
    CPFSGT  TBLPTRL ;if pointer is still within boundaries,skip	    
    GOTO    reset_neg_regs ;pointer is outside boundaries, reset		    
    BTFSS   button_2 ;checks that button_2 is still pressed 
    GOTO    button_setup ;if not pressed, got to button setup to hold value 
    RETURN ;return to decrementation loop
    
reset_pos_regs: ;positioned there for convienence
    MOVLW      0x00 ;setting the upper table pointer at 0x00
    MOVWF      TBLPTRU
    MOVLW      0x01  ;setting the higher table pointer at 0x01
    MOVWF      TBLPTRH
    MOVLW      0x60  ;setting the higher table pointer at 0x60
    MOVWF      TBLPTRL
    
button_1_pushed: 
    BTFSC   button_2 ;checks if both are pressed
    GOTO    check_reset ;if now button_2 is pushed too, got to reset
    RCALL   display ;function to display value 
    RCALL   check_table_incr ;checks seg table pointers
    RCALL   delay ;calls roughly 1 min delay
    INCF    TBLPTRL, F ;increments table poiinters to be ahead of display
    GOTO    button_1_pushed ;loops incrementation

display: ;functions to display 7 segment values
    TBLRD*
    MOVFF   TABLAT, PORTD
    RETURN
    
check_table_incr: ;checks seg table pointer
    MOVLW   0x70 ;puts value that is last on the seg table in WREG		    
    CPFSLT  TBLPTRL ;compares WREG to our lower table pointer (ahead)		    
    GOTO    reset_pos_regs ;if out of bounds, resets table pointers 
    BTFSS   button_1 ;if in bounds, rechecks button pressed
    GOTO    button_setup ;if button_1 is pressed, value is held and buttons are rechecked
    RETURN ;returns to incrementation loop
    
delay: ;delay of roughly 1 second
    MOVLW INNER_LOOP_2
    MOVWF INNER_LOOP_2_REG
    
_outer_loop:  
    MOVLW INNER_LOOP
    MOVWF INNER_LOOP_REG
    
_loop_delay:
    DECF  INNER_LOOP_REG,F
    NOP
    NOP
    BNZ	 _loop_delay
    DECF INNER_LOOP_2_REG
    BZ	_end_of_loop
    GOTO _outer_loop
_end_of_loop:
    RETURN      

ORG 0x160
SEG_TABLE:  DB  0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D ;0-5 in display
	    DB  0x7D, 0x07, 0x7F, 0x6F,0x77 ; 6-10 in display
	    DB  0x7C, 0x39, 0x5E, 0x79 ; B-E in display
	    DB 0x71 ; F (15) in display
	


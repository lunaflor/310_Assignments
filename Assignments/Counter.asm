;---------------------
; Initialization
;---------------------
#include "C:\Users\lunaf\MPLABXProjects\Counter.X\AssemblyConfig.inc"
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
   
Ports:
    BANKSEL PORTD
    CLRF PORTD
    BANKSEL LATD
    CLRF LATD
    BANKSEL ANSELD
    CLRF ANSELD
    BANKSEL TRISD
    CLRF TRISD
   
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
    MOVLW      0x00 ; setting the upper table pointer at 0x00
    MOVWF      TBLPTRU
    MOVLW      0x01  ; setting the higher table pointer at 0x01
    MOVWF      TBLPTRH
    MOVLW      0x60  ; setting the higher table pointer at 0x60
    MOVWF      TBLPTRL
    ;CALL check_buttons

    check_reset:
    BTFSC button_1 ; Check if button_1 is pressed, skip if not
    GOTO both_pressed

    button_setup:
    BTFSC button_1 ;bit tests on RC0 input and skips if not being pushed
    GOTO button_1_pushed
    BTFSC button_2 ;bit tests on RC1 input and skips if not being pushed
    GOTO button_2_pushed
    GOTO check_reset
   
both_pressed:
    BTFSS button_2
    GOTO button_setup
    MOVLW  0x60  ; setting the higher table pointer at 0x60 (which is 0)
    MOVWF  TBLPTRL
    TBLRD*
    MOVFF TABLAT, PORTD
    CALL delay
    GOTO button_setup
   
button_1_pushed:
    TBLRD*+
    MOVLW 0xFF
    CPFSEQ TABLAT
    GOTO button_display
    NOP
    GOTO regs_setup
   
regs_setup_decrement: ;made to start decrementing program
    MOVLW      0x00 ; setting the upper table pointer at 0x00
    MOVWF      TBLPTRU
    MOVLW      0x01  ; setting the higher table pointer at 0x01
    MOVWF      TBLPTRH
    MOVLW      0x6F  ; setting the higher table pointer at 0x6F
    MOVWF      TBLPTRL
    GOTO check_reset
   
button_display:
    MOVFF TABLAT, PORTD
    CALL delay
    GOTO check_reset

button_2_pushed:
    TBLRD*-
    MOVLW 0xFF
    CPFSEQ TABLAT
    GOTO button_display
    NOP
    GOTO regs_setup_decrement
   
button_decrement:
    MOVFF TABLAT, PORTD
    CALL delay
    GOTO check_reset
   
 
delay:
    ;NOP
    MOVLW INNER_LOOP_2
    MOVWF INNER_LOOP_2_REG
   
_outer_loop:  ;roughly make 1 second
    MOVLW INNER_LOOP
    MOVWF INNER_LOOP_REG
   
_loop_delay:
    DECF  INNER_LOOP_REG,F
    NOP
    NOP
    BNZ _loop_delay
    DECF INNER_LOOP_2_REG
    BZ _end_of_loop
    GOTO _outer_loop
_end_of_loop:
    RETURN      

ORG 0x160
SEG_TABLE:  DB  0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D ;0-5 in display
   DB  0x7D, 0x07, 0x7F, 0x6F,0x77 ; 6-10 in display
   DB  0x7C, 0x39, 0x5E, 0x79 ; B-E in display
   DB 0x71 ; F (15) in display

//-----------------------------
// Title: First Assembly Program
//-----------------------------
// Purpose: The program is a heating and cooling control system.
// The basic idea is that the user sets the desired temperature.
// If the environment temperature is higher than the reference temperature,
// the cooling system will be turned on. On the other hand,
// if the environment temperature falls below the reference temperature,
// the heating systems will start. 

// Dependencies:AssemblyConfig.inc
// Compiler: XC8(v2.46)
// Author: Flor Luna 
// OUTPUTS: HEATING_SYSTEM - connected to PORTD.1,
// and COOLING_SYSTEM - connected to PORTD.2 
// INPUTS: Measured temperature(measuredTemp) and reference temperature(refTemp)
// Versions:
//  	V1.0: 02/28/2024 - First version 
//  	V1.2: 02/29/2024 - Second version
//	V2.3: 03/03/2024 - Third version
//--------------------	
;---------------------
; Initialization
;---------------------
#include "C:\Users\lunaf\MPLABXProjects\Heating_and_cooling_system.X\AssemblyConfig.inc"
#include <xc.inc>
;---------------------
; Definitions
;---------------------
#define HEATING_SYSTEM	  PORTD, 1 //Output for PORTD.1
#define COOLING_SYSTEM	  PORTD, 2 //Output for PORTD.2
;---------------------
; Program Inputs
;---------------------
input_refTemp EQU 23		//+10 Degree celsius and +50 Degree celsius. 
input_measuredTemp EQU 5	//-20 Degree celsius and +60 Degree celsius 
;---------------------
; Registers
;---------------------
refTemp EQU 0x20  //register for reference Temp
measuredTemp EQU 0x21 //register for measured Temp
contReg EQU 0x22 //register for counting 

refTemp_L EQU 0x60 //register for LSB of refTemp
refTemp_M EQU 0x61 //register for middle bit of refTemp
refTemp_H EQU 0x62 //register for MSB of refTemp

measuredTemp_L EQU 0x70 //register for LSB of measuredTemp
measuredTemp_M EQU 0x71 //register for middle bits of measuredTemp
measuredTemp_H EQU 0x72 //register for MSB of measuredTemp
 
REG_L EQU 0x80 //arbitrary register for LSB (least significant bit)
REG_M EQU 0x81 //arbitrary register for middle bit
REG_H EQU 0x82 //arbitrary register for MSB (most significant bit)
 
num EQU 0x15 //RAM location for input
qu EQU 0x16 //RAM location for quotient
denom EQU 10 //denominator to divide by
;---------------------
; Main Program
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
 
	ORG	00		;Reset vector
	GOTO	START
	ORG	0x20		;Begin assembly at 0x20
START:
	CLRF TRISD ;sets all bits to outputs
	CLRF PORTD ;initializes PORTD
	
	;move inputs into input registers
	MOVLW input_refTemp
	MOVWF refTemp
	MOVLW input_measuredTemp
	MOVWF measuredTemp
	
	;convert hex to decimal
	RCALL Hex_to_Decimal
	
	;test if measuredTemp is neg
	MOVF measuredTemp, W 
	BTFSC WREG,7 ;test bit 7 of WREG, skip if clear
	GOTO LED_COLD ;if negative
	MOVF refTemp, W 
	CPFSEQ  measuredTemp ;Compare F with W, skip if F = W
	GOTO check_less ;check if measuredTemp<refTemp	
LED_OFF: 
	GOTO STOP ;goes to STOP which ends program
	
check_less: ;check if measuredTemp<refTemp
	CPFSLT  measuredTemp ;Compare F with W, skip if F < W
	GOTO LED_HOT ;if F>W
	
LED_COLD:;measuredTemp<refTemp, contReg=1
	INCF contReg,0x01 ;increment for countreg
	BSF HEATING_SYSTEM ;turn on PORTD.1
	GOTO STOP 
	
LED_HOT:;measuredTemp>refTemp, contReg=2
	INCF contReg,0x01 ;increment contreg
	INCF contReg,0x01 ;increment for countreg
	BSF COOLING_SYSTEM ;turns on PORTD.2
	GOTO STOP 
	
Hex_to_Decimal: ;convert hex to decimal for refTemp first
	MOVLW input_refTemp ;loads refTemp input to num (first loop)
	;loop for measuredTemp 
AGAIN:  MOVWF num ;move input into num
	MOVLW denom ;WREG = 10
	CLRF qu ;clears quotient
	
loop_1:	INCF qu, F ;increments qu for every subtraction
	SUBWF num, F ;subract WREG from num (input value)
	BC loop_1 ;checks carry flag, if set then loop
	
	ADDWF num, F ;add wreg to num to compensate for over-subtracting
	DECF qu, F ;decrement 1 from qu to compensate for over-looping
	MOVFF num, REG_L ;save the first digit
	MOVFF qu, num ;move quotient to input
	CLRF qu ;clear quotient for next loop
	
loop_2:	INCF qu, F ;increments quotient for every subtraction
	SUBWF num, F ;subract WREG from num (input value)
	BC loop_2 ;checks carry flag, if set then loop
	ADDWF num, F ;move wreg into input to commpensate for over-looping
	DECF qu, F ;decrement qu by 1 to compensate for over-looping
	MOVFF num, REG_M ;scond digit
	MOVFF qu, REG_H ;third digit

	BTFSS contReg, 0 ;check if anything is inside contReg
	GOTO last_conversion_loop
	
	MOVFF REG_L, measuredTemp_L ;move registers to refTemp registers
	MOVFF REG_M, measuredTemp_M
	MOVFF REG_H, measuredTemp_H
	CLRF contReg
	RETURN
	
last_conversion_loop:   
	MOVFF REG_L, refTemp_L ;move registers to refTemp registers
	MOVFF REG_M, refTemp_M
	MOVFF REG_H, refTemp_H
	INCF contReg,0x01
	
	MOVF measuredTemp, W ;move measuredTemp to WREG
	BTFSC WREG,7 ;test bit 7 of WREG, if clear, skip
	NEGF WREG ;2's compliment of WREG
	GOTO AGAIN ;hex to decimal for negative measuredTemp
STOP:
    END ;end program

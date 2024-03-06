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
// OUTPUTS: RD1 - connected to PORTD.1, and RD2 - connected to PORTD.2 
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
input_refTemp EQU 15		//+10 Degree celsius and +50 Degree celsius. 
input_measuredTemp EQU 0	//-20 Degree celsius and +60 Degree celsius 
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
 
sel_input EQU 0x13 //register to keep track of hex to dec loops
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
	
Comperator:  
	MOVF measuredTemp, W 
	BTFSC WREG,7 ;test bit 7 of WREG, skip if clear
	GOTO LED_COLD ;if negative
	MOVF refTemp, W 
	CPFSEQ  measuredTemp ;Compare F with W, skip if F = W
	GOTO check_less ;check if measuredTemp<refTemp
	
LED_OFF: 
	GOTO STOP ;goes to STOP which ends program
	
check_less: ;check if measuredTemp<refTemp
	INCF contReg,0x01 ;increment for countreg
	CPFSLT  measuredTemp ;Compare F with W, skip if F < W
	GOTO LED_HOT ;if F>W
	
LED_COLD:;measuredTemp<refTemp, contReg=1
	BSF HEATING_SYSTEM ;turn on PORTD.1
	GOTO STOP 
	
LED_HOT:;measuredTemp>refTemp, contReg=2
	INCF contReg,0x01 ;increment contreg
	BSF COOLING_SYSTEM ;turns on PORTD.2
	GOTO STOP 
	
Hex_to_Decimal: ;convert hex to decimal for refTemp first
	MOVLW input_refTemp ;loads refTemp input to NUME (first loop)
	
AGAIN:  MOVWF num ;loop for measuredTemp 
	MOVLW denom ;WREG =10
	CLRF qu ;clears quotient
	
loop_1:	INCF qu, F ;increments quotient for every subtraction
	SUBWF num, F ;subract WREG from NUME value (input value)
	BC loop_1 ;if positive, go back (C=1)
	ADDWF num, F ;once too many, this is our first digit 
	DECF qu, F ;once too many for quoitent
	MOVFF num, REG_L ;save the first digit
	MOVFF qu, num ;repeat process again
	CLRF qu ;clear quotient
	
loop_2:	INCF qu, F ;increments quotient for every subtraction
	SUBWF num, F ;subract WREG from NUME value (input value)
	BC loop_2 ;if positive, go back (C=1)
	ADDWF num, F 
	DECF qu, F
	MOVFF num, REG_M ;scond digit
	MOVFF qu, REG_H ;third digit

	BTFSS sel_input, 0
	GOTO check_neg_conversion
	;hex conversion done for both temps
	MOVFF REG_L, measuredTemp_L ;move registers to refTemp registers
	MOVFF REG_M, measuredTemp_M
	MOVFF REG_H, measuredTemp_H
	RETURN
	
check_neg_conversion:
	;hex conversion done for loop one (refTemp) but need loop 2 (measuredTemp)
	MOVFF REG_L, refTemp_L ;move registers to refTemp registers
	MOVFF REG_M, refTemp_M
	MOVFF REG_H, refTemp_H
	INCF sel_input,0x01
	;check if measuredTemp is neg
	MOVF measuredTemp, W ;move measuredTemp to WREG
	BTFSS WREG,7 ;test bit 7 of WREG, if set (neg) then skip
	GOTO AGAIN ;hex to decimal for measuredTemp
	
	;measuredTemp IS neg
	MOVF measuredTemp, W ;move measuredTemp to WREG
	NEGF WREG ;2's compliment of WREG
	GOTO AGAIN ;hex to decimal for negative measuredTemp

STOP:
    END ;end program

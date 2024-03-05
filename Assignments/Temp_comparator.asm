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
#define HEATER	  PORTD, 1
#define COOLER	  PORTD, 2
;---------------------
; Program Inputs
;---------------------
input_refTemp EQU 5 //+10 Degree celsius and +50 Degree celsius. 
input_measuredTemp EQU -5 //-20 Degree celsius and +60 Degree celsius 
;---------------------
; Registers
;---------------------
refTemp EQU 0x20
measuredTemp EQU 0x21
contReg EQU 0x22

refTemp_L EQU 0x60 //LSB of refTemp
refTemp_M EQU 0x61 //middle bits of refTemp
refTemp_H EQU 0x62 //MSB of refTemp

measuredTemp_L EQU 0x70
measuredTemp_M EQU 0x71
measuredTemp_H EQU 0x72
 
NUME EQU 0x15 ;RAM location for NUME
QU EQU 0x16 ;RAM location for quotient
MYDEN EQU 10
;---------------------
; Main Program
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
 
	ORG	00		;Reset vector
	GOTO	START

	ORG	0x20		;Begin assembly at 0x20
START:

	;move inputs into storage
	MOVLW input_refTemp
	MOVWF refTemp
	MOVLW input_measuredTemp
	MOVWF measuredTemp

	;Check for negative inputs
	GOTO Hex_to_Decimal
BEGIN:  
	;if measuredTemp = refTemp, contReg = 0
	MOVF refTemp, W
	CPFSEQ  measuredTemp	;Compare F with W, skip if F = W
	GOTO check_less_or_greater
	GOTO SEG_OFF

check_less_or_greater:
	;measuredTemp<refTemp ? contReg=1
	CPFSLT  measuredTemp	;Compare F with W, skip if F < W
	GOTO check_if_greater
	GOTO SEG_COLD

check_if_greater:
	;measuredTemp>refTemp ? contReg=2
	GOTO SEG_HOT

SEG_OFF:;if measuredTemp = refTemp, contReg = 0
	SLEEP


SEG_COLD:;measuredTemp<refTemp ? contReg=1
	INCF contReg, 0x01
	MOVLW 0X00
	MOVWF TRISD
	MOVLW 0X00
	MOVWF PORTD
	BSF HEATER; Additionally, turn on PORTD.1
	SLEEP

SEG_HOT:;measuredTemp>refTemp, contReg=2
	INCF contReg,0x01
	INCF contReg,0x01
	MOVLW 0X00
	MOVWF TRISD
	MOVLW 0x00
	MOVWF PORTD
	BSF COOLER ; Additionally, turn on PORTD.2
	SLEEP

check_if_neg:
	MOVF measuredTemp, W ;moved measuredTemp to WREG
	BTFSS WREG,7 ;test bit 7 of WREG, if set (neg) then skip
	GOTO Continue
	GOTO NEGATIVE_CONFIRMED

Hex_to_Decimal: ;convert hex to decimal for refTemp
	MOVLW input_refTemp
	MOVWF NUME
	MOVLW MYDEN
	CLRF QU
D_1:	INCF QU, F
	SUBWF NUME, F
	BC D_1
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, refTemp_L
	MOVFF QU, NUME
	CLRF QU
D_2:	INCF QU, F
	SUBWF NUME, F
	BC D_2
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, refTemp_M
	MOVFF QU, refTemp_H
	
	CLRF QU
	CLRF NUME
	CLRF MYDEN
	
	GOTO check_if_neg 
	
	;negative numbers too
Continue:
	MOVLW input_measuredTemp ;convert hex to decimal for measuredTemp
        MOVWF NUME
	MOVLW MYDEN
	CLRF QU
D_3:	INCF QU, F
	SUBWF NUME, F
	BC D_3
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, measuredTemp_L
	MOVFF QU, NUME
	CLRF QU
D_4:	INCF QU, F
	SUBWF NUME, F
	BC D_4
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, measuredTemp_M
	MOVFF QU, measuredTemp_H

	GOTO BEGIN
	
NEGATIVE_CONFIRMED: ;convert hex to decimal for negative measuredTemp
	MOVF measuredTemp, W
	NEGF WREG 
        MOVWF NUME
	MOVLW MYDEN
	CLRF QU
D_5:	INCF QU, F
	SUBWF NUME, F
	BC D_5
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, measuredTemp_L
	MOVFF QU, NUME
	CLRF QU
D_6:	INCF QU, F
	SUBWF NUME, F
	BC D_6
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, measuredTemp_M
	MOVFF QU, measuredTemp_H
	GOTO SEG_COLD
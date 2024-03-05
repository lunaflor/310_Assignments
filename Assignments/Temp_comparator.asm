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
input_refTemp EQU 20		//+10 Degree celsius and +50 Degree celsius. 
input_measuredTemp EQU -5	//-20 Degree celsius and +60 Degree celsius 
;---------------------
; Registers
;---------------------
refTemp EQU 0x20
measuredTemp EQU 0x21
contReg EQU 0x22

refTemp_L EQU 0x60 
refTemp_M EQU 0x61 
refTemp_H EQU 0x62 

measuredTemp_L EQU 0x70
measuredTemp_M EQU 0x71
measuredTemp_H EQU 0x72
 
REG_L EQU 0x80
REG_M EQU 0x81
REG_H EQU 0x82
 
input_selection EQU 0x13
input_selection_reg EQU 0x14
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
	GOTO Hex_to_Decimal

Comperator:  
	MOVF measuredTemp, W ;moved measuredTemp to WREG
	BTFSS WREG,7 ;test bit 7 of WREG, if clear (not negative) then skip
	GOTO SEG_COLD
	;if measuredTemp = refTemp, contReg = 0
	MOVF refTemp, W
	CPFSEQ  measuredTemp	;Compare F with W, skip if F = W
	GOTO check_less
	GOTO SEG_OFF
SEG_OFF:
	GOTO STOP ;if measuredTemp = refTemp, contReg = 0

check_less:
	;measuredTemp<refTemp, contReg=1
	CPFSLT  measuredTemp	;Compare F with W, skip if F < W
	GOTO check_greater
	GOTO SEG_COLD

check_greater:
	;measuredTemp>refTemp, contReg=2
	GOTO SEG_HOT
SEG_HOT:;measuredTemp>refTemp, contReg=2
	INCF contReg,0x01
	INCF contReg,0x01
	MOVLW 0X00
	MOVWF TRISD
	MOVLW 0x00
	MOVWF PORTD
	BSF COOLER ; Additionally, turn on PORTD.2
	GOTO STOP

SEG_COLD:;measuredTemp<refTemp ? contReg=1
	INCF contReg, 0x01
	MOVLW 0X00
	MOVWF TRISD
	MOVLW 0X00
	MOVWF PORTD
	BSF HEATER; Additionally, turn on PORTD.1
	GOTO STOP

Hex_to_Decimal: ;convert hex to decimal for refTemp
	MOVLW input_refTemp
AGAIN:  MOVWF NUME
	INCF input_selection,0x01
	MOVLW MYDEN
	CLRF QU
D_1:	INCF QU, F
	SUBWF NUME, F
	BC D_1
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, REG_L
	MOVFF QU, NUME
	CLRF QU
D_2:	INCF QU, F
	SUBWF NUME, F
	BC D_2
	ADDWF NUME, F
	DECF QU, F
	MOVFF NUME, REG_M
	MOVFF QU, REG_H
	CLRF QU
	CLRF NUME
	CLRF MYDEN
	GOTO check_input_selection
check_neg_conversion:
	MOVFF REG_L, refTemp_L
	MOVFF REG_M, refTemp_M
	MOVFF REG_H, refTemp_H
	MOVF measuredTemp, W ;moved measuredTemp to WREG
	BTFSS WREG,7 ;test bit 7 of WREG, if set (neg) then skip
	GOTO AGAIN
	MOVF measuredTemp, W
	NEGF WREG 
	GOTO AGAIN

check_input_selection:
	MOVLW 0x02
	MOVWF input_selection_reg
	MOVF input_selection, W
	CPFSEQ  input_selection_reg	;Compare F with W, skip if F = W
	GOTO check_neg_conversion
	MOVFF REG_L, measuredTemp_L
	MOVFF REG_M, measuredTemp_M
	MOVFF REG_H, measuredTemp_H
	GOTO Comperator
STOP:
    END
	

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
input_measuredTemp EQU 20	//-20 Degree celsius and +60 Degree celsius 
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
 
input_selection EQU 0x13 //register to initially hold input_selection
input_selection_reg EQU 0x14 //register for input_selection comperating
NUME EQU 0x15 //RAM location for NUME
QU EQU 0x16 //RAM location for quotient
MYDEN EQU 10 //denominator to divide by
;---------------------
; Main Program
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
 
	ORG	00		;Reset vector
	GOTO	START
	ORG	0x20		;Begin assembly at 0x20
START:
	;move inputs into input registers
	MOVLW input_refTemp
	MOVWF refTemp
	MOVLW input_measuredTemp
	MOVWF measuredTemp
	
	;convert hex to decimal
	GOTO Hex_to_Decimal
	
Comperator:  
	MOVF measuredTemp, W ;move measuredTemp to WREG
	BTFSC WREG,7 ;test bit 7 of WREG, if clear (not negative) then skip
	GOTO SEG_COLD ;if negative, go directly to SEG_COLD
	MOVF refTemp, W ;move refTemp to WREG
	CPFSEQ  measuredTemp ;Compare F with W, skip if F = W
	GOTO check_less ;check if measuredTemp<refTemp, contReg=1
	GOTO SEG_OFF ;if measuredTemp = refTemp, contReg = 0
	
SEG_OFF: ;if measuredTemp = refTemp, contReg = 0
	GOTO STOP ;goes to STOP which ends program
	
check_less: ;check if measuredTemp<refTemp, contReg=1
	CPFSLT  measuredTemp ;Compare F with W, skip if F < W
	GOTO SEG_HOT ;if F>W
	GOTO SEG_COLD ;if F<W
	
SEG_HOT:;measuredTemp>refTemp, contReg=2
	INCF contReg,0x01 ;increment for countreg
	INCF contReg,0x01 ;repeat incrementation
	MOVLW 0X00 ;load 0x00 to TRISD
	MOVWF TRISD ;sets all bits to outputs
	MOVLW 0x00 ;load 0x00 to PORTD
	MOVWF PORTD ;initializes PORTD
	BSF COOLING_SYSTEM ;turns on PORTD.2
	GOTO STOP ;goes to end program
	
SEG_COLD:;measuredTemp<refTemp, contReg=1
	INCF contReg, 0x01 ;increment for countreg
	MOVLW 0X00 ;load 0x00 to TRISD
	MOVWF TRISD ;sets all bits to outputs
	MOVLW 0x00 ;load 0x00 to PORTD
	MOVWF PORTD ;initializes PORTD
	BSF HEATING_SYSTEM ;turn on PORTD.1
	GOTO STOP ; goes to end program 
	
Hex_to_Decimal: ;convert hex to decimal for refTemp first
	MOVLW input_refTemp ;loads refTemp input to NUME (first loop)
	
AGAIN:  MOVWF NUME ;loop for measuredTemp 
	INCF input_selection,0x01 ;keeps track of loops
	MOVLW MYDEN ;WREG =10
	CLRF QU ;clears quotient
D_1:	INCF QU, F ;increments quotient for every subtraction
	SUBWF NUME, F ;subract WREG from NUME value (input value)
	BC D_1 ;if positive, go back (C=1)
	ADDWF NUME, F ;once too many, this is our first digit 
	DECF QU, F ;once too many for quoitent
	MOVFF NUME, REG_L ;save the first digit
	MOVFF QU, NUME ;repeat process again
	CLRF QU ;clear quotient
D_2:	INCF QU, F ;increments quotient for every subtraction
	SUBWF NUME, F ;subract WREG from NUME value (input value)
	BC D_2 ;if positive, go back (C=1)
	ADDWF NUME, F 
	DECF QU, F
	MOVFF NUME, REG_M ;scond digit
	MOVFF QU, REG_H ;third digit
	
	;clear paramaters to setup for second loop 
	CLRF QU 
	CLRF NUME
	CLRF MYDEN
	GOTO check_input_selection ;checks if we need another hex to decimal loop
	
check_neg_conversion:
	;hex conversion done for loop one (refTemp) but need loop 2 (measuredTemp)
	MOVFF REG_L, refTemp_L ;move registers to refTemp registers
	MOVFF REG_M, refTemp_M
	MOVFF REG_H, refTemp_H
	
	;check if measuredTemp is neg
	MOVF measuredTemp, W ;move measuredTemp to WREG
	BTFSS WREG,7 ;test bit 7 of WREG, if set (neg) then skip
	GOTO AGAIN ;hex to decimal for measuredTemp
	
	;measuredTemp IS neg
	MOVF measuredTemp, W ;move measuredTemp to WREG
	NEGF WREG ;2's compliment of WREG
	GOTO AGAIN ;hex to decimal for negative measuredTemp

check_input_selection: ;check to see if we are on our first or second loop 
	MOVLW 0x02 ;load 0x02 into WREG
	MOVWF input_selection_reg ;load 0x02 to input selection reg
	MOVF input_selection, W ;move input_selection into WREG
	CPFSEQ  input_selection_reg ;if W=2, hex to decimal conversion is done
	GOTO check_neg_conversion ;still need hex to decimal for measured Temp
	
	;hex conversion done for both loops (refTemp & measuredTemp)
	MOVFF REG_L, measuredTemp_L ;move registers to refTemp registers
	MOVFF REG_M, measuredTemp_M
	MOVFF REG_H, measuredTemp_H
	
	GOTO Comperator ;time to compare temps
STOP:
    END ;end program

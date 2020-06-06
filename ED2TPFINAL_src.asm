	LIST P=16F887
	;RADIX HEX
; CONFIG1
; __config 0xFFF2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
#include "p16f887.inc"

W_TEMP EQU 0x20
STATUS_TEMP EQU 0x21
COLUMN EQU 0x22 ; VARIABLE DECIMAL DE LA COLUMNA
ROW EQU 0x23 ; VARIABLE DECIMAL DE LA FILA
COL_EN EQU 0x24 ; VARIABLE DONDE SE GUARDA LA COLUMNA ACTIVADA
COL_EN_T EQU 0x25 ; VARIABLE DONDE SE GUARDA LA COLUMNA ACTIVADA TEMPORAL
N_COL EQU 3 ; CANTIDAD MAXIMA DE COLUMNAS
N_ROW EQU 4 ; CANTIDAD MAXIMA DE FILAS
FLAGS EQU 0x26 ; BIT FLAG QUE ENTRO EN INTERRUPT
INTRB EQU 0
FLANCO EQU 1
   
   ORG 0x00  
   GOTO INIT

   ORG 0x04
   GOTO INTERRUPT_SERVE

   ORG 0x05
INIT 
   BANKSEL TRISC
   MOVLW 0x0F
   MOVWF TRISB
   CLRF TRISC
   BCF OPTION_REG, 7 ; ACTIVO PULL UP EN PUERTO B
   MOVLW 0x0F
   MOVWF WPUB ; ACTIVO PULL UP EN PINES DE ENTRADA
   BSF INTCON, GIE ; ACTIVO INTERRUPCIONES GLOBALES
   BSF INTCON, RBIE ; ACTIVO INTERRUPCIONES POR PUERTO B
   MOVLW 0x0F
   MOVWF IOCB ; ACTIVO INTERRUPCIONES EN LOS PINES PORTB<3:0> SON ENTRADA
   
   BANKSEL TRISD
   CLRF TRISD ; DEBUG
   
   BANKSEL ANSELH
   CLRF ANSELH
   
   BANKSEL PORTC
   CLRF PORTB
   CLRF PORTC
   BSF PORTC, 0
   CLRF FLAGS
   BANKSEL PORTD
   CLRF PORTD
   GOTO PROGRAMA
  
PROGRAMA
   CALL CHECK_TECLADO
   GOTO PROGRAMA

CHECK_TECLADO
   BTFSS FLAGS, INTRB
   RETURN
   MOVF PORTB, W
   ANDLW 0x0F
   MOVWF COL_EN
   MOVWF COL_EN_T
   CLRF COLUMN 
   CLRF ROW
   CALL COL_DEC
   BCF STATUS, C
   MOVF COLUMN, W
   ADDWF ROW, W
   ADDWF ROW, W
   ADDWF ROW, W
   MOVWF PORTC
   BCF FLAGS, INTRB
   RETURN
   
COL_DEC
   RRF COL_EN_T, F
   BTFSS STATUS, C
   GOTO ROW_DEC
   INCF COLUMN, F
   MOVLW N_COL
   SUBWF COLUMN, W
   BTFSS STATUS, Z
   GOTO COL_DEC
   CLRF COLUMN
   GOTO FINEXP
ROW_DEC
   MOVF ROW, W
   CALL EN_ROW
   MOVWF PORTB
   MOVF PORTB, W
   ANDLW 0x0F
   SUBWF COL_EN, W
   BTFSC STATUS, Z
   GOTO FINEXP
   INCF ROW, F
   MOVLW N_ROW
   SUBWF ROW, W
   BTFSS STATUS, Z
   GOTO ROW_DEC
   CLRF ROW
   GOTO FINEXP

INTERRUPT_SERVE
   BTFSS INTCON, RBIF
   GOTO ENDINT
   CALL CHECKBITS
   BTFSC FLAGS, FLANCO
   GOTO ENDINT
   BSF FLAGS, INTRB
   ;GOTO ENDINT
ENDINT
   MOVF PORTB, W
   BCF INTCON, 0
   BSF PORTD, 0
   RETFIE
   
FINEXP
   CLRF PORTB
   BCF FLAGS, INTRB
   RETURN
   
EN_ROW
   ADDWF PCL, F
   RETLW 0xE0; COL0
   RETLW 0xD0; COL1                
   RETLW 0xB0; COL2
   RETLW 0x70; COL3
   
CHECKBITS
   BSF FLAGS, FLANCO ; BIT DE BANDERA DE CAMBIO DE FLANCO
   BTFSS PORTB, 0
   BCF FLAGS, FLANCO
   BTFSS PORTB, 1
   BCF FLAGS, FLANCO
   BTFSS PORTB, 2
   BCF FLAGS, FLANCO
   BTFSS PORTB, 3
   BCF FLAGS, FLANCO
   RETURN
   
   END
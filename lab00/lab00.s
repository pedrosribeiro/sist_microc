; Exemplo.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 12/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
BASE_RAM_ADDR 	EQU 0x20000400
MAX_COUNT_ADDR 	EQU 0x20000500
; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		
; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a função Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma função externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; função <func>
; -------------------------------------------------------------------------------
; Função main()
Start  
	LDR 	R0, =STRING1		; Load address of STRING1 into R0
	MOVS 	R3, #0				; R3 will count the maximum amount
	
	LDR		R8, =MAX_COUNT_ADDR	; Load address of MAX_COUNT_ADDR into R8
	
	LDR		R4, =BASE_RAM_ADDR 	; Occurrence vector address
	MOVS	R5, #26				; Occurrence vector size (26 letters of the alphabet)
	MOV		R6, #0				; Initialize R6 to zero
	
	MOV		R7, #0				; Initialize occurrence vector with zeros

; Write data to a sequential memory area
INIT_VECTOR
	STRB	R7, [R4], #1		; Stores the value of R7 in memory at the address pointed to by R4 and then increments the value of R4 by 1 byte
	SUBS	R5, R5, #1			; Decrements vector size
	BNE		INIT_VECTOR

SCAN_LOOP
	LDR		R4, =BASE_RAM_ADDR	; INIT_VECTOR shifted R4 by 26 bytes, now it points back to the beginning of the vector
	; Loads a byte of data from memory, located at the address pointed to by R0, into register R6 and then increments the value of R0 by 1 byte
    LDRB	R6, [R0], #1		; Loads the next character of the string into R6
    CMP		R6, #0				; Checks if the end of the string has been reached
    BEQ		DONE
	
	; Checks if the character is an uppercase letter (between 'A' and 'Z')
    CMP		R6, #'A'			; Compares with 'A'
    BLT		NOT_UPPER_CASE
    CMP		R6, #'Z'			; Compares with 'Z'
    BGT		NOT_UPPER_CASE
	
	SUBS	R6, R6, #'A'		; Calculates the position in the occurrence vector (A=0, B=1, ..., Z=25)
    LDRB	R7, [R4, R6]		; Loads current letter count into R7
    ADD		R7, R7, #1			; Increment the corresponding letter count
    STRB	R7, [R4, R6]		; Update the occurrence vector
	
	; Checks if the current count is greater than the maximum count
    CMP		R7, R3
    BLE		SCAN_LOOP
	
	; If current count is greater, update max count
    MOV		R3, R7
    STRB	R3, [R8]			; Update memory position MAX_COUNT_ADDR

    B		SCAN_LOOP

NOT_UPPER_CASE
    B		SCAN_LOOP

DONE
    B		.

STRING1 DCB "PARANGARICOTIRRIMIRRUARO", 0

ALIGN                           ; garante que o fim da seção está alinhada 
END                             ; fim do arquivo

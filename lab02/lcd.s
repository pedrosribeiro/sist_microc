; lcd.s
; Desenvolvido para a placa EK-TM4C1294XL
; Template by Prof. Guilherme Peron - 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma fun��o do arquivo for chamada em outro arquivo
		; EXPORT <func>				; Permite chamar a fun��o a partir de outro arquivo
		EXPORT LCD_Init
		EXPORT LCD_Line2
		EXPORT LCD_PrintString
		EXPORT LCD_Reset
									
		; Se chamar alguma fun��o externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma fun��o de outro
		IMPORT PortM_Output			; Permite chamar PortM_Output de outro arquivo
		IMPORT PortK_Output			; Permite chamar PortK_Output de outro arquivo
		IMPORT SysTick_Wait1ms		; Permite chamar SysTick_Wait1ms de outro arquivo
; -------------------------------------------------------------------------------
; Fun��o LCD_Init
; Inicializa o LCD
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
LCD_Init
	PUSH {LR}
	
	MOV R3, #0x38		; Inicializar no modo 2 linhas/caracter matriz 5x7
	BL LCD_Instruction
	
	MOV R3, #0x06		; Cursor com autoincremento para direita
	BL LCD_Instruction
	
	MOV R3, #0x0E		; Configurar o cursor (habilitar o display + cursor + n�o-pisca)
	BL LCD_Instruction
	
	MOV R3, #0x01		; Resetar: Limpar o display e levar o cursor para o home
	BL LCD_Instruction
	
	POP {LR}
	BX LR

; Fun��o LCD_Instruction
; Recebe uma instru��o e a executa
; Par�metro de entrada: R3
; Par�metro de sa�da: N�o tem
LCD_Instruction
	PUSH {LR}
	
	MOV R0, #2_00000100	; Ativa o modo de instru��o (EN=1, RW=0, RS=0)
	BL PortM_Output
	
	MOV R0, R3			; Escreve no barramento de dados
	BL PortK_Output
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necess�rios)
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000	; Desativa o modo de instru��o (EN=0, RW=0, RS=0)
	BL PortM_Output
	
	POP {LR}
	BX LR

; Fun��o LCD_Data
; Recebe um dado e o escreve
; Par�metro de entrada: R3
; Par�metro de sa�da: N�o tem
LCD_Data
	PUSH {LR}
	
	MOV R0, #2_00000101	; Ativa o modo de dados (EN=1, RW=0, RS=1)
	BL PortM_Output
	
	MOV R0, R3			; Escreve no barramento de dados
	BL PortK_Output
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necess�rios)
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000	; Desativa o modo de dados (EN=0, RW=0, RS=0)
	BL PortM_Output
	
	POP {LR}
	BX LR

; Fun��o LCD_Line2
; Prepara a escrita na segunda linha do LCD
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
LCD_Line2
	PUSH {LR}
	
	MOV R3, #0xC0		; Endere�o da primeira posi��o - Segunda Linha
	BL LCD_Instruction
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necess�rios)
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR

; Fun��es LCD_PrintString, LCD_PrintChar e LCD_EndOfString
; Imprimem uma string no LCD atrav�s de um loop
; Par�metro de entrada: R4 -> A string a ser escrita
; Par�metro de sa�da: N�o tem
LCD_PrintString
	PUSH {LR}
LCD_PrintChar
	LDRB R3, [R4], #1	; L� um caractere da string e desloca para o pr�ximo
	
	CMP R3, #0			; Verifica se chegou no final da string
	BEQ LCD_EndOfString
	
	BL LCD_Data			; Escreve o caractere
	
	B LCD_PrintChar		; Continua iterando sobre a string at� chegar no fim
LCD_EndOfString
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necess�rios)
	BL SysTick_Wait1ms
	
	POP {LR}			; A string foi escrita. Retorna
	BX LR

; Fun��o LCD_Reset
; Limpa o display e leva o cursor para o home
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
LCD_Reset
	PUSH {LR}
	
	MOV R3, #0x01		; Resetar: Limpar o display e levar o cursor para o home
	BL LCD_Instruction
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necess�rios)
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR
; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo

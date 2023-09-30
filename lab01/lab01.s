; lab01.s
; Desenvolvido para a placa EK-TM4C1294XL
; Template by Prof. Guilherme Peron - 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
BASE_RAM_ADDR 	EQU 0x20000400
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
        EXPORT Start                ; Permite chamar a fun��o Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma fun��o externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; fun��o <func>
		IMPORT  PLL_Init
		IMPORT  SysTick_Init
		IMPORT  SysTick_Wait1ms			
		IMPORT  GPIO_Init
        IMPORT	PortA_Output		; Permite chamar PortA_Output de outro arquivo
		IMPORT	PortB_Output		; Permite chamar PortB_Output de outro arquivo
		IMPORT	PortJ_Input         ; Permite chamar PortJ_Input de outro arquivo
		IMPORT	PortP_Output		; Permite chamar PortP_Output de outro arquivo
		IMPORT	PortQ_Output		; Permite chamar PortQ_Output de outro arquivo			

; Mapeamento dos 7 segmentos (0 a F)
MAPEAMENTO_7SEG DCB	0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
; -------------------------------------------------------------------------------
; Fun��o main()
Start  		
	BL PLL_Init                 ; Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init				; Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                ; Chama a subrotina que inicializa os GPIO
	
	MOV R4, #2_11				; Estado dos bot�es
	MOV R5, #1					; Tabuada
	MOV R6, #1					; Multiplicador
	MUL R7, R5, R6				; Resultado da multiplica��o (R5xR6)
	
	; Registradores usados inicialmente para inicilizar o espa�o de mem�ria da RAM
	MOV R10, #9					; N�mero de tabuadas
	MOV R11, #0					; Zero
	LDR R12, =BASE_RAM_ADDR		; Carrega o endere�o base da RAM

InitMemory						; Zera as posi��es de mem�ria da base at� a �ltima tabuada
	STRB	R11, [R12], #1		; Stores the value of R11 in memory at the address pointed to by R12 and then increments the value of R12 by 1 byte
	SUBS	R10, R10, #1		; Decrements vector size
	BNE		InitMemory

MainLoop
	BL PortJ_Input				; Chama a subrotina que l� o estado das chaves e coloca o resultado em R0
	
	CMP R0, R4					; Verifica se o estado dos bot�es mudou
	BEQ MultiplicaAtualiza		; Se n�o, somente imprime
			
	BIC R3, R4, R0				; Verifica a transi��o do estado dos bot�es (Solto -> pressionado)

VerificaSW1
	CMP R3, #2_00000010			; Verifica se apenas SW1 est� pressionada
	BNE	VerificaSW2				; Testa SW2
	
	ADD R6, R6, #1				; Incrementa o multiplicador
			
	CMP R6, #0X9				; Verifica se j� o mutiplicador j� passou de 9
	IT HI
		MOVHI R6, #0			; Se sim, volta para 0
	
	LDR	R12, =BASE_RAM_ADDR		; Carrega o endere�o base da RAM
	STRB R6, [R12, R5]			; Guarda o valor do multiplicador atual na sua posi��o correta (BASE deslocada por R5)

VerificaSW2
	CMP R3, #2_00000001			; Verifica se apenas SW2 est� pressionada
	BNE MultiplicaAtualiza
		
	ADD R5, R5, #1				; Incrementa a tabuada
	
	CMP R5, #0X8				; Verifica se a tabuada j� passou de 8
	IT HI
		MOVHI R5, #1			; Se sim, volta para 1

MultiplicaAtualiza
	LDR	R12, =BASE_RAM_ADDR		; Carrega o endere�o base da RAM
	LDRB R12, [R12, R5]			; Carrega o multiplicador da ocorr�ncia anterior
	MOV R6, R12					; Move para o multiplicador atual o valor do multiplicador anterior

	MOV R4, R0					; Atualiza o estado dos bot�es
	MUL R7, R5, R6				; Realiza a opera��o de multiplica��o
	
	MOV R12, #10
	UDIV R8, R7, R12			; Guarda o d�gito da dezena em R8
	MLS R9, R8, R12, R7			; Guarda o d�gito da unidade em R9

Display
	MOV R0, R9					; Envia o d�gito da unidade para o DS1
	BL WriteDS1
	MOV R0, R8
	BL WriteDS2					; Envia o d�gito da dezena para o DS2
	MOV R0, R5
	BL WriteLEDs				; Envia o n�mero da tabuada atual para os LEDs
	
	B MainLoop					; Depois de tudo atualizado, retoma o loop principal

WriteLEDs
	PUSH {LR}					; Guarda o endere�o de retorno
	
	MOV R10, #0
	MOV R11, R0					; Copia a base

LoadLEDs
	CMP R11, #0
	ITTTT HI					; Loop para carregar os devidos LEDs
		LSLHI R10, R10, #1		; Desloca um bit para esquerda
		ADDHI R10, R10, #1		; Incrementa um LED
		SUBHI R11, R11, #1		; Decrementa o passo do loop
		BHI LoadLEDs
	
	AND R0, R10, #2_11110000	; Atualiza
	BL PortA_Output
	
	AND R0, R10, #2_00001111	; Atualiza
	BL PortQ_Output

	MOV R0, #2_00100000			; Ativa o transistor dos LEDs (PP5)
	BL PortP_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000			; Desativa o transistor dos LEDs (PP5)
	BL PortP_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR						; Retoma

WriteDS1
	PUSH {LR}					; Guarda o endere�o de retorno
	
	LDR  R11, =MAPEAMENTO_7SEG	; Desloca escolhendo o respectivo n�mero das dezenas
	LDRB R10, [R11, R0]
	
	AND R0, R10, #2_11110000	; Atualiza
	BL PortA_Output
	
	AND R0, R10, #2_00001111	; Atualiza
	BL PortQ_Output

	MOV R0, #2_00100000			; Ativa o transistor do DS2 (PB5)
	BL PortB_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000			; Desativa o transistor do DS2 (PB5)
	BL PortB_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR						; Retoma

WriteDS2
	PUSH {LR}					; Guarda o endere�o de retorno
	
	LDR  R11, =MAPEAMENTO_7SEG	; Desloca escolhendo o respectivo n�mero das unidades
	LDRB R10, [R11, R0]
	
	AND R0, R10, #2_11110000	; Atualiza
	BL PortA_Output
	
	AND R0, R10, #2_00001111	; Atualiza
	BL PortQ_Output

	MOV R0, #2_00010000			; Ativa o transistor do DS1 (PB4)
	BL PortB_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000			; Desativa o transistor do DS1 (PB4)
	BL PortB_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR						; Retoma

; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo

; lab01.s
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

; -------------------------------------------------------------------------------
; Fun��o main()
Start  		
	BL PLL_Init                 ; Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init				; Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                ; Chama a subrotina que inicializa os GPIO
	
	MOV	R4,	#1					; Tabuada = 1 (Come�a na tabuada do 1)
	MOV R5, #1					; Multiplicador = 1 (Come�a com multiplicador 1)
	
	MOV R6, #0					; Enables dos Displays 7-seg (DS1 e DS2) e LEDs (LED0:LED8)
	
	MOV R7, #0					; Resultado da multiplica��o entre R4 e R5
	
	MOV R8, #0					; Tempo para trocar os n�meros
	
	MOV R9, #0					; Contador das dezenas
	MOV R10,#0					; Contador das unidades
	
	MOV	R11, #2_10000000		; LEDs (indica a tabuada atual, ent�o come�a com o primeiro ligado)
	MOV R12, #2_10000000		; LEDs (registrador auxiliar)

MainLoop
	BL PortJ_Input				; Chama a subrotina que l� o estado das chaves e coloca o resultado em R0

VerificaNenhuma					; Verifica se nenhuma chave est� pressionada (Pressionada -> 0)
	CMP	R0, #2_00000011
	BNE	VerificaSW1				; Testa SW1
	BEQ	InitDisplaysLEDs		; Inicializa os displays e os LEDs
	B	MainLoop				; Retoma o loop principal

VerificaSW1
	CMP	R0, #2_00000010			; Verifica se apenas SW1 est� pressionada
	BNE	VerificaSW2				; Testa SW2
	BEQ	IncrementaTabuada		; Incrementa a tabuada
	BX LR						; Volta para VerificaNenhuma
	
VerificaSW2
	CMP	R0, #2_00000001			; Verifica se apenas SW2 est� pressionada
	BEQ	IncrementaMultiplicador	; Incrementa o multiplicador
	BX LR						; Volta para VerificaSW1

IncrementaTabuada
	CMP		R4, #8				; Verifica se chegou na tabuada do 8 (�ltima)
	ADDNE	R4, R4, #1			; Se n�o chegou, incrementa
	MOVEQ	R4, #1				; Se j� chegou na tabuada do 8, volta para a tabuada do 1
	
	BL MultExtraindoDigitos 	; Chamada da sub-rotina de multiplica��o e extra��o de d�gitos
	
	MOV		R0, #150			; Atrasa 150ms
	BL		SysTick_Wait1ms
	B		MainLoop			; Retoma o loop principal

IncrementaMultiplicador
	CMP		R5, #9				; Verifica se o multiplicador chegou em 9 (�ltimo)
	ADDNE	R5, R5, #1			; Se n�o chegou, incrementa
	MOVEQ	R5, #0				; Se j� chegou no multiplicador 9, volta para o multiplicador 0
	
	BL MultExtraindoDigitos 	; Chamada da sub-rotina de multiplica��o e extra��o de d�gitos
	
	MOV		R0, #150			; Atrasa 150ms
	BL		SysTick_Wait1ms
	B		MainLoop			; Retoma o loop principal

MultExtraindoDigitos
	MUL R7, R4, R5   			; Multiplica R4 e R5 e armazena o resultado em R7
	MOV R9, R7, LSR #4			; Move o d�gito da dezena (4 bits mais significativos) para R9
	AND R10, R7, #0xF			; Mascara os 4 bits menos significativos para obter o d�gito da unidade
	BX LR						; Retorna da sub-rotina

InitDisplaysLEDs
	CMP R6, #0
	BEQ EnableDS1				; Enable do DS1
	
	CMP R6, #1
	BEQ EnableDS2				; Enable do DS2
	
	CMP R6, #2
	BEQ EnableLEDs				; Enable doS LEDs
	
	MOV R6, #0					; Default enable
	ADD R8, #1					; Cada atualiza��o dos displays conta um tempo
	
	B MainLoop					; Retoma o loop principal

EnableDS1
	MOV	R6, #1					; Prepara o enable do DS2
	
	MOV	R0, #2_00000000			; Desativa o transistor dos LEDs (PP5)
	BL	PortP_Output
	
	MOV	R0, #2_00010000			; Ativa o transistor do DS1 (PB4)
	BL	PortB_Output
	
	B	DS1						; Mostra o valor atual da dezena

EnableDS2
	MOV	R6, #2					; Prepara o enable dos LEDs
	
	MOV	R0, #2_00100000			; Ativa o transistor do DS2 (PB5)
	BL	PortB_Output
	
	B	DS2						; Mostra o valor atual da unidade

EnableLEDs
	MOV	R6, #3					; Para o enable em um valor inv�lido para n�o entrar mais no Init
	
	MOV	R0, #2_00000000			; Desativa os transistores dos displays
	BL	PortB_Output
	
	MOV	R0, #2_00100000			; Ativa o transistor dos LEDs (PP5)
	BL	PortP_Output
	
	MOV	R0,	R11					; Acende os LEDs
	B	Saida

DS1								; Display das dezenas
	CMP	R9, #0
	BEQ Zero
	
	CMP	R9, #1
	BEQ	Um
	
	CMP	R9, #2
	BEQ	Dois
	
	CMP	R9, #3		
	BEQ	Tres
	
	CMP	R9, #4
	BEQ	Quatro
	
	CMP	R9, #5
	BEQ	Cinco
	
	CMP	R9, #6
	BEQ	Seis
	
	CMP	R9, #7
	BEQ	Sete					; O valor m�ximo a ser mostrado � 72 (8x9)
	
	BGT	OitoDS1					; Zera DS1 corrigindo DS2

DS2								; Display das unidades
	CMP	R10, #0
	BEQ	Zero
	
	CMP	R10, #1
	BEQ	Um
	
	CMP	R10, #2
	BEQ	Dois
	
	CMP	R10, #3
	BEQ	Tres
	
	CMP	R10, #4
	BEQ	Quatro
	
	CMP	R10, #5
	BEQ	Cinco
	
	CMP	R10, #6
	BEQ	Seis
	
	CMP	R10, #7
	BEQ	Sete
	
	CMP	R10, #8
	BEQ	Oito
	
	CMP	R10, #9
	BEQ	Nove
	
	BGT	DezDS2					; Incrementa DS1 quando DS2 > 9

Zero
	MOV	R0, #2_00111111
	B	Saida

Um
	MOV	R0, #2_00000110
	B	Saida

Dois
	MOV	R0, #2_01011011
	B	Saida

Tres
	MOV	R0, #2_01001111
	B	Saida

Quatro
	MOV	R0, #2_01100110
	B	Saida

Cinco
	MOV	R0, #2_01101101
	B	Saida

Seis
	MOV	R0, #2_01111101
	B	Saida

Sete
	MOV	R0, #2_00000111
	B	Saida

Oito
	MOV	R0, #2_01111111
	B	Saida

Nove
	MOV	R0, #2_01101111
	B	Saida

OitoDS1
	MOV	R9, #0						; Contador de dezenas vai pra 0
	MOV	R6, #1						; Enable DS2
	B	MainLoop					; Retoma o loop principal

DezDS2
	SUB	R10, R10, #10				; Contador de unidades joga uma dezena fora
	ADD	R9, #1						; Incrementa o contador das dezenas
	MOV	R6, #0						; Enable DS1
	B	MainLoop					; Retoma o loop principal

Saida
	BL	PortA_Output				; LEDs
	BL	PortQ_Output				; Displays
	
	MOV	R0, #5						; Atrasa 5ms
	BL	SysTick_Wait1ms
	
	CMP	R8,	#40						; Tempo para trocar de n�mero
	BEQ	AcendeLEDs
	
	B	MainLoop					; Retoma o loop principal

AcendeLEDs							; Executado a cada tempo
	MOV	R8, #0						; Volta o tempo para zero
	
	CMP R11, #2_11111111			; Verifica se todos os LEDs est�o acesos
	
	BNE AcendeProxLED				; Se n�o est�o, acende o pr�ximo
	BEQ ResetLEDs					; Se est�o, apaga todos

AcendeProxLED
	LSR	R12, R12 , #1				; Desloca o bit do auxiliar para a direita
	ADD	R11, R11, R12				; Acende o pr�ximo
	
	B	MainLoop					; Retoma o loop principal

ResetLEDs
	MOV	R11, #2_10000000			; Volta para a configura��o inicial (tabuada do 1)
	MOV	R12, #2_10000000
	B	MainLoop					; Retoma o loop principal

; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo

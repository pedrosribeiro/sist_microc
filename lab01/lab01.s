; lab01.s
; Desenvolvido para a placa EK-TM4C1294XL
; Template by Prof. Guilherme Peron - 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
BASE_RAM_ADDR 	EQU 0x20000400
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
; Função main()
Start  		
	BL PLL_Init                 ; Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init				; Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                ; Chama a subrotina que inicializa os GPIO
	
	MOV R4, #2_11				; Estado dos botões
	MOV R5, #1					; Tabuada
	MOV R6, #1					; Multiplicador
	MUL R7, R5, R6				; Resultado da multiplicação (R5xR6)
	
	; Registradores usados inicialmente para inicilizar o espaço de memória da RAM
	MOV R10, #9					; Número de tabuadas
	MOV R11, #0					; Zero
	LDR R12, =BASE_RAM_ADDR		; Carrega o endereço base da RAM

InitMemory						; Zera as posições de memória da base até a última tabuada
	STRB	R11, [R12], #1		; Stores the value of R11 in memory at the address pointed to by R12 and then increments the value of R12 by 1 byte
	SUBS	R10, R10, #1		; Decrements vector size
	BNE		InitMemory

MainLoop
	BL PortJ_Input				; Chama a subrotina que lê o estado das chaves e coloca o resultado em R0
	
	CMP R0, R4					; Verifica se o estado dos botões mudou
	BEQ MultiplicaAtualiza		; Se não, somente imprime
			
	BIC R3, R4, R0				; Verifica a transição do estado dos botões (Solto -> pressionado)

VerificaSW1
	CMP R3, #2_00000010			; Verifica se apenas SW1 está pressionada
	BNE	VerificaSW2				; Testa SW2
	
	ADD R6, R6, #1				; Incrementa o multiplicador
			
	CMP R6, #0X9				; Verifica se já o mutiplicador já passou de 9
	IT HI
		MOVHI R6, #0			; Se sim, volta para 0
	
	LDR	R12, =BASE_RAM_ADDR		; Carrega o endereço base da RAM
	STRB R6, [R12, R5]			; Guarda o valor do multiplicador atual na sua posição correta (BASE deslocada por R5)

VerificaSW2
	CMP R3, #2_00000001			; Verifica se apenas SW2 está pressionada
	BNE MultiplicaAtualiza
		
	ADD R5, R5, #1				; Incrementa a tabuada
	
	CMP R5, #0X8				; Verifica se a tabuada já passou de 8
	IT HI
		MOVHI R5, #1			; Se sim, volta para 1

MultiplicaAtualiza
	LDR	R12, =BASE_RAM_ADDR		; Carrega o endereço base da RAM
	LDRB R12, [R12, R5]			; Carrega o multiplicador da ocorrência anterior
	MOV R6, R12					; Move para o multiplicador atual o valor do multiplicador anterior

	MOV R4, R0					; Atualiza o estado dos botões
	MUL R7, R5, R6				; Realiza a operação de multiplicação
	
	MOV R12, #10
	UDIV R8, R7, R12			; Guarda o dígito da dezena em R8
	MLS R9, R8, R12, R7			; Guarda o dígito da unidade em R9

Display
	MOV R0, R9					; Envia o dígito da unidade para o DS1
	BL WriteDS1
	MOV R0, R8
	BL WriteDS2					; Envia o dígito da dezena para o DS2
	MOV R0, R5
	BL WriteLEDs				; Envia o número da tabuada atual para os LEDs
	
	B MainLoop					; Depois de tudo atualizado, retoma o loop principal

WriteLEDs
	PUSH {LR}					; Guarda o endereço de retorno
	
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
	PUSH {LR}					; Guarda o endereço de retorno
	
	LDR  R11, =MAPEAMENTO_7SEG	; Desloca escolhendo o respectivo número das dezenas
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
	PUSH {LR}					; Guarda o endereço de retorno
	
	LDR  R11, =MAPEAMENTO_7SEG	; Desloca escolhendo o respectivo número das unidades
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
    ALIGN                        ;Garante que o fim da seção está alinhada 
    END                          ;Fim do arquivo

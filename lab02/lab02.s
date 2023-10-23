; lab02.s
; Desenvolvido para a placa EK-TM4C1294XL
; Template by Prof. Guilherme Peron - 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; Defini��es do estado do cofre
GET_PASSWORD	EQU 0
SET_PASSWORD	EQU 1
OPENING			EQU 2
OPEN			EQU 3
CLOSING			EQU 4
CLOSED			EQU 5
LOCKED			EQU 6
LOCKED_MASTER	EQU 7
; Defini��es gerais
MAX_PASSWORD_ATTEMPTS	EQU 3
; O INVALID_DIGIT deve conter pelo menos 8 bits, caso contr�rio, pode resultar no aumento do contador de acertos
INVALID_DIGIT			EQU 256 ; Representa um d�gito inv�lido do teclado matricial
INVALID_PW_CHAR			EQU -1	; Representa um caractere imposs�vel de estar na senha
WAIT_HASH_CONFIRM		EQU 100	; Valor aleat�rio s� para sinalizar o estado de aguardando # ser pressionado
; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		
PASSWORDS SPACE 8			; 4 bytes para a senha do usu�rio e 4 bytes para a senha mestra
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
		IMPORT PLL_Init
		IMPORT SysTick_Init
		IMPORT SysTick_Wait1ms			
		
		IMPORT GPIO_Init
		IMPORT PortA_Output
		IMPORT PortP_Output
		IMPORT PortQ_Output
			
		IMPORT LCD_Init
		IMPORT LCD_Line2
		IMPORT LCD_Reset
		IMPORT LCD_PrintString
		
		IMPORT MapMatrixKeyboard
			
; -------------------------------------------------------------------------------
Start  		
	BL PLL_Init				; Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init			; Chama a subrotina para inicializar o SysTick
	BL GPIO_Init			; Chama a subrotina que inicializa os GPIO
	BL LCD_Init				; Chama a subrotina que inicializa o LCD
	
	; R0, R1 e R2 reservados
	; R3 usado para instru��es e dados do LCD
	; R4 usado para os textos do LCD
	MOV R5, #GET_PASSWORD	; R5 usado para o estado do cofre
	MOV R6, #INVALID_DIGIT	; R6 usado para guardar o d�gito lido do teclado
	MOV R7, #0				; R7 usado para contar quantos d�gitos o usu�rio digitou
	LDR R8, =PASSWORDS		; R8 usado para apontar a posi��o da senha salva na mem�ria
	MOV R9, #INVALID_PW_CHAR; R9 usado para ler os caracteres da senha salva na mem�ria
	STRB R9, [R8]
	MOV R10, #0				; R10 usado para contar quantos d�gitos o usu�rio acertou
	MOV R11, #0				; R11 usado para contar quantos erros de senha aconteceram
	; R12 usado para configurar a senha mestra na mem�ria e como registrador auxiliar
	BL SetMasterPassword
	
	B MainLoop

; Fun��o SetMasterPassword
; Guarda a senha mestra na mem�ria
; Par�metro de entrada: R8 -> Endere�o aonde a senha deve ser armazenada
; Par�metro de sa�da: N�o tem
SetMasterPassword
	PUSH {LR}
	
	MOV R12, #1				; Primeiro d�gito da senha mestra
	STRB R12, [R8, #5]		; Senha mestra � armazenada 4 bytes a frente da senha do usu�rio
	MOV R12, #2				; Segundo d�gito da senha mestra
	STRB R12, [R8, #6]
	MOV R12, #3				; Terceiro d�gito da senha mestra
	STRB R12, [R8, #7]
	MOV R12, #4				; Quarto d�gito da senha mestra
	STRB R12, [R8, #8]
	MOV R12, #0
	
	POP {LR}
	BX LR

; Fun��o MainLoop
; Loop principal do programa
; Par�metro de entrada: R5 -> Estado atual do cofre
; Par�metro de sa�da: N�o tem
MainLoop

	CMP R5, #CLOSED			; Verifica se o cofre j� est� fechado
	BEQ ClosedFunction
	
	CMP R5, #GET_PASSWORD	; Estado inicial do cofre. Pede a senha para fech�-lo
	BEQ.W GetPassword		; Branch offset out of range (BEQ.W corrige o problema)
	
	CMP R5, #SET_PASSWORD	; Configura a senha que o usu�rio digitou
	BEQ.W SetPassword		; Branch offset out of range (BEQ.W corrige o problema)
	
	CMP R5, #CLOSING		; Coloca o cofre em processo de fechamento
	BEQ.W ClosingFunction	; Branch offset out of range (BEQ.W corrige o problema)

	B MainLoop

; Fun��es ClosedFunction e CheckPassword
; Verifica a senha digitada enquanto o cofre est� fechado
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
ClosedFunction
	BL LCD_Line2			; Coloca o cursor no come�o da segunda linha
	
	LDR R4, =EMPTY_STR		; Imprime uma string vazia na segunda linha
	BL LCD_PrintString
	
	BL LCD_Line2			; Depois do cursor ser deslocado para o fim, posiciona de volta no come�o

	MOV R7, #0				; O usu�rio ainda n�o inseriu d�gitos. Zera o contador
	MOV R10, #0				; O usu�rio ainda n�o acertou nenhum d�gito. Zera o contador
	MOV R6, #INVALID_DIGIT	; Nenhum d�gito foi lido. Coloca R6 em estado inv�lido (reset)
CheckPassword
	BL MapMatrixKeyboard	; L� o d�gito pressionado no teclado e guarda em R6
	
	LDRB R9, [R8, R7]		; Desloca o ponteiro da senha em R7 bytes, onde R7 � o contador de d�gitos inseridos
	
	CMP R6, R9				; Compara o d�gito inserido com o d�gito da senha salva na mem�ria
	ADDEQ R10, R10, #1		; Incrementa o contador de acertos se o usu�rio acertou o caractere atual
	
	MOV R6, #INVALID_DIGIT	; Depois de contabilizado, invalida R6 e R9 para evitar erros
	MOV R9, #INVALID_PW_CHAR
	
	CMP R10, #4				; Verifica se o usu�rio j� acertou os 4 d�gitos da senha
	BEQ OpenFunction		; Se acertou, abre o cofre
	
	CMP R7, #4				; 4 d�gitos j� foram inseridos, mas usu�rio n�o acertou
	BEQ WrongPassword		; Inseriu uma senha incorreta
	
	B CheckPassword			; Continua lendo os d�gitos se ainda est� inserindo

; Fun��o WrongPassword
; Mostra mensagem de erro de senha no display e trava o cofre se excedeu o m�ximo de tentativas
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
WrongPassword
	BL LCD_Reset					; Limpa o display e coloca o cursor em home
	
	LDR R4, =WRONG_PASSWORD_STR		; Imprime mensagem de senha incorreta no display
	BL LCD_PrintString
	
	MOV R0, #1000					; Mostra a mensagem de erro durante 1s
	BL SysTick_Wait1ms
	
	CMP R11, #MAX_PASSWORD_ATTEMPTS	; Verifica se chegou no n�mero m�ximo de tentativas de senha
	ADDNE R11, R11, #1				; Se n�o chegou, incrementa o contador
	
	CMP R11, #MAX_PASSWORD_ATTEMPTS	; Se a tentativa atual � o m�ximo, trava o cofre
	BEQ LockedFunction
	
	MOV R7, #0						; Zera o contador de d�gitos inseridos
	
	B ClosedFunction				; Ainda restam tentativas -> Retoma a rotina de verifica��o de senha

; Fun��es LockedFunction, MasterPasswordError, WaitPJ0_Interrupt e CheckMasterPassword
; Mostra mensagem de cofre travado com senha mestra e aguarda usu�rio pressionar PJ0 e inserir senha mestra para destravar
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
LockedFunction
	MOV R5, #LOCKED_MASTER		; Cofre foi travado e precisa da senha mestra para ser destravado
MasterPasswordError
	MOV R6, #INVALID_DIGIT		; Invalida o d�gito lido do teclado para evitar erros
	MOV R7, #4					; R7 = 4 para ignorar os primeiros 4 bytes da mem�ria em PASSWORDS (acessar senha mestra)
	MOV R10, #0					; Zera o contador de d�gitos acertados
	
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =LOCKED_MASTER_STR	; Mostra a mensagem de erro senha mestra
	BL LCD_PrintString
WaitPJ0_Interrupt
	BL StartBlinkingLEDs		; Chama a rotina que pisca todos os LEDs da placa auxiliar
	CMP R5, #LOCKED				; Verifica se PJ0 foi pressionado para sair do modo travado senha mestra para travado
	BNE WaitPJ0_Interrupt
	BL LCD_Line2				; Coloca o cursor no come�o da segunda linha
CheckMasterPassword
	BL MapMatrixKeyboard		; L� o d�gito pressionado no teclado e guarda em R6
	
	LDRB R9, [R8, R7]			; L� um d�gito da senha mestra
	CMP R6, R9					; Compara com o d�gito inserido
	ADDEQ R10, R10, #1			; Se estiver certo, incrementa o contador de acertos
	
	MOV R6, #INVALID_DIGIT		; Depois de contabilizado, invalida R6 e R9 para evitar erros
	MOV R9, #INVALID_PW_CHAR
	
	CMP R10, #4					; Verifica se os 4 d�gitos corretos foram inseridos
	BEQ UnlockFunction			; Destrava o cofre
	
	CMP R7, #8					; Verifica se j� leu 4 d�gitos, mas n�o foram os certos
	BEQ LockedFunction			; Retoma a rotina de pedir interrup��o do PJ0 e senha mestra
	
	B CheckMasterPassword		; Se nada disso aconteceu, continua lendo os d�gitos

; Fun��o StartBlinkingLEDs
; Pisca todos os LEDs da placa auxiliar
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
StartBlinkingLEDs
	PUSH {LR}
	
	MOV R0, #2_100000			; Ativa o transistor dos LEDs (PP5)
	BL PortP_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	MOV R0, #2_11110000			; Ativa os LEDs PA7:PA4
	BL PortA_Output
	MOV R0, #2_00001111			; Ativa os LEDs PQ3:PQ0
	BL PortQ_Output
	
	MOV R0, #100				; LEDs ativados durante 100ms
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000			; Desativa os LEDs PA7:PA4 e PQ3:PQ0
	BL PortA_Output
	BL PortQ_Output
	
	MOV R0, #100				; LEDs desativados durante 100ms
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR

; Fun��o StopBlinkingLEDs
; Desativa o transistor dos LEDs (para de piscar todos os LEDs da placa auxiliar)
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
StopBlinkingLEDs
	PUSH {LR}
	
	MOV R0, #2_000000			; Desativa o transistor dos LEDs (PP5)
	BL PortP_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR

; Fun��o UnlockFunction
; Para de piscar os LEDs da placa e abre o cofre
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
UnlockFunction
	BL StopBlinkingLEDs			; Para de piscar todos os LEDs da placa auxiliar

	B OpenFunction				; Abre o cofre

; Fun��o OpenFunction
; Zera registradores e coloca o cofre em estado de pedir senha (cofre aberto)
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
OpenFunction
	MOV R5, #GET_PASSWORD		; Coloca o cofre em estado de pedir senha
	MOV R6, #INVALID_DIGIT		; Invalida R6 com valor fora do intervalo
	MOV R7, #0					; Zera o contador de d�gitos inseridos
	MOV R10, #0					; Zera o contador de d�gitos acertados
	MOV R11, #0					; Zera o contador de erros de senha
	MOV R12, #0					; Zera o registrador auxiliar
	
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =OPENING_STR		; Imprime a mensagem abrindo cofre
	; Esse erro parou de aparecer, ent�o comentei a linha
	;LTORG						; Error: Literal pool too distant, use LTORG to assemble it within 4KB
	BL LCD_PrintString
	
	MOV R0, #5000				; Mostra a mensagem durante 5s
	BL SysTick_Wait1ms
	
	B MainLoop					; Retoma o loop principal

; Fun��o GetPassword
; Mostra a mensagem de inserir nova senha e coloca o cofre em estado de configurar a nova senha
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
GetPassword
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =OPEN_STR			; Informa que o cofre est� aberto na primeira linha do LCD
	BL LCD_PrintString
	
	BL LCD_Line2
	LDR R4, =GET_PASSWORD_STR	; Pede nova senha na segunda linha do LCD
	BL LCD_PrintString
	
	MOV R0, #500				; Mostra a mensagem na segunda linha do LCD durante 0,5s
	BL SysTick_Wait1ms
	
	BL LCD_Line2
	LDR R4, =EMPTY_STR			; Limpa a segunda linha do LCD
	BL LCD_PrintString
	
	BL LCD_Line2				; Coloca o cursor no come�o da segunda linha
	
	MOV R5, #SET_PASSWORD		; Coloca o cofre em estado de cadastrar a nova senha
	
	B MainLoop					; Retoma o loop principal no estado de cadastrar a nova senha

; Fun��o SetPassword
; Mostra a mensagem de confirma��o de senha usando # e aguarda # ser inserida para avan�ar para o estado de fechando cofre
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
SetPassword
	BL MapMatrixKeyboard		; L� o d�gito pressionado no teclado e guarda em R6
	
	CMP R12, #WAIT_HASH_CONFIRM	; Flag de 4 d�gitos inseridos e aguardando a confirma��o com #
	BEQ CheckHashConfirmation
	
	STRB R6, [R8, R7]			; Guarda o d�gito inserido na mem�ria sequencialmente
	
	CMP R7, #4					; Verifica se 4 d�gitos foram inseridos
	BLT SetPassword				; Se n�o, retoma o loop para receber o pr�ximo
	
	BL LCD_Reset				; Se sim, limpa o display e coloca o cursor em home
	
	LDR R4, =HASH_CONFIRM_STR	; Imprime a mensagem de confirma��o da senha usando #
	BL LCD_PrintString
	
	MOV R12, #WAIT_HASH_CONFIRM	; Flag de 4 d�gitos inseridos e aguardando a confirma��o com #
CheckHashConfirmation
	CMP R5, #CLOSING			; Verifica se o estado do cofre � fechando (DIGIT_HASH no matrix_keyboard.s altera R5 para CLOSING)
	BNE SetPassword				; Se ainda n�o for, volta para configurar a senha
	B MainLoop					; Retoma o loop principal

; Fun��o ClosingFunction
; Mostra a mensagem que o cofre est� fechando, fecha o cofre e mostra que est� fechado
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
ClosingFunction
	MOV R0, #1000				; Aguarda 1s antes de iniciar o processo de fechamento do cofre
	BL SysTick_Wait1ms
	
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =CLOSING_STR		; Imprime a mensagem de fechando cofre
	BL LCD_PrintString
	
	MOV R0, #5000				; Mostra a mensagem durante 5s
	BL SysTick_Wait1ms
	
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =CLOSED_STR			; Imprime a mensagem de cofre fechado na primeira linha do LCD
	BL LCD_PrintString
	
	BL LCD_Line2				; Coloca o cursor no come�o da segunda linha
	LDR R4, =ENTER_PASSWORD_STR	; Pede para o usu�rio inserir a senha na segunda linha do LCD
	BL LCD_PrintString
	
	MOV R0, #1000				; Aguarda 1s antes de mudar o estado do cofre para trancado
	BL SysTick_Wait1ms
	
	MOV R5, #CLOSED				; Coloca o cofre em estado de fechado
	
	B MainLoop					; Retoma o loop principal

; Defini��o dos textos do LCD com 16 caracteres cada
OPENING_STR	DCB "Abrindo         ", 0
OPEN_STR	DCB "Cofre aberto    ", 0
CLOSING_STR	DCB "Fechando        ", 0
CLOSED_STR	DCB "Cofre fechado   ", 0

LOCKED_MASTER_STR DCB "ERR Senha mestra", 0

HASH_CONFIRM_STR DCB "Confirme com #  ", 0
GET_PASSWORD_STR DCB "Digite nova senh", 0

ENTER_PASSWORD_STR DCB "Digite a senha ", 0

EMPTY_STR	DCB "                ", 0

WRONG_PASSWORD_STR DCB "ERR Senha errada", 0
; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN					; Garante que o fim da se��o est� alinhada 
    END						; Fim do arquivo

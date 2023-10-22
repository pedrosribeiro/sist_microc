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
MAX_PASSWORD_ATTEMPT EQU 3
; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		
PASSWORD SPACE 4			; Senha de 4 caracteres (4 bytes)
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
	MOV R6, #16				; R6 usado para guardar o d�gito lido do teclado
	MOV R7, #0				; R7 usado para contar quantos d�gitos o usu�rio digitou
	LDR R8, =PASSWORD		; R8 usado para apontar a posi��o da senha salva na mem�ria
	MOV R9, #-1				; R9 usado para ler os caracteres da senha salva na mem�ria
	MOV R10, #0				; R10 usado para contar quantos d�gitos o usu�rio acertou
	MOV R11, #0				; R11 usado para contar quantos erros de senha aconteceram
	
	B MainLoop

MainLoop

	CMP R5, #CLOSED			; Verifica se o cofre j� est� fechado
	BEQ ClosedFunction
	
	CMP R5, #GET_PASSWORD	; Estado inicial do cofre. Pede a senha para fech�-lo
	BEQ GetPassword
	
	CMP R5, #SET_PASSWORD	; Configura a senha que o usu�rio digitou
	BEQ SetPassword
	
	CMP R5, #CLOSING		; Coloca o cofre em processo de fechamento
	BEQ ClosingFunction

	B MainLoop

; Fun��es ClosedFunction e CheckPassword
; Verifica a senha digitada enquanto o cofre est� fechado
; Par�metro de entrada:
; Par�metro de sa�da:
ClosedFunction
	BL LCD_Line2			; Coloca o cursor no come�o da segunda linha
	
	LDR R4, =EMPTY_STR		; Imprime uma string vazia na segunda linha
	BL LCD_PrintString
	
	BL LCD_Line2			; Depois do cursor ser deslocado para o fim, posiciona de volta no come�o

	MOV R7, #0				; O usu�rio ainda n�o inseriu d�gitos. Zera o contador
	MOV R10, #0				; O usu�rio ainda n�o acertou nenhum d�gito. Zera o contador
	MOV R6, #16				; Nenhum d�gito foi lido. Coloca R6 em estado inv�lido (reset)
CheckPassword
	BL MapMatrixKeyboard
	
	LDRB R9, [R8, R7]		; Desloca o ponteiro da senha em R7 bytes, onde R7 � o contador de d�gitos inseridos
	
	CMP R6, R9				; Compara o d�gito inserido com o d�gito da senha salva na mem�ria
	ADDEQ R10, R10, #1		; Incrementa o contador de acertos se o usu�rio acertou o caractere atual
	
	MOV R6, #16				; Depois de contabilizado, invalida R6 e R9 para evitar erros
	MOV R9, #-1
	
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
	
	CMP R11, #MAX_PASSWORD_ATTEMPT	; Verifica se chegou no n�mero m�ximo de tentativas de senha
	ADDNE R11, R11, #1				; Se n�o chegou, incrementa o contador
	
	CMP R11, #MAX_PASSWORD_ATTEMPT	; Se a tentativa atual � o m�ximo, trava o cofre
	BEQ LockedFunction
	
	MOV R7, #0						; Zera o contador de d�gitos inseridos
	
	B ClosedFunction				; Ainda restam tentativas -> Retoma a rotina de verifica��o de senha

LockedFunction
	; --

OpenFunction
	; --

GetPassword
	; --

SetPassword
	; --

ClosingFunction
	; --

; Defini��o dos textos do LCD com 16 caracteres cada
OPENING_STR	DCB "Abrindo         ", 0
OPEN_STR	DCB "Cofre aberto    ", 0
CLOSING_STR	DCB "Fechando        ", 0
CLOSED_STR	DCB "Cofre fechado   ", 0

EMPTY_STR	DCB "                ", 0

WRONG_PASSWORD_STR DCB "ERR Senha errada ", 0
; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN					; Garante que o fim da se��o est� alinhada 
    END						; Fim do arquivo

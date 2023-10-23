; lab02.s
; Desenvolvido para a placa EK-TM4C1294XL
; Template by Prof. Guilherme Peron - 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; Definições do estado do cofre
GET_PASSWORD	EQU 0
SET_PASSWORD	EQU 1
OPENING			EQU 2
OPEN			EQU 3
CLOSING			EQU 4
CLOSED			EQU 5
LOCKED			EQU 6
LOCKED_MASTER	EQU 7
; Definições gerais
MAX_PASSWORD_ATTEMPTS	EQU 3
; O INVALID_DIGIT deve conter pelo menos 8 bits, caso contrário, pode resultar no aumento do contador de acertos
INVALID_DIGIT			EQU 256 ; Representa um dígito inválido do teclado matricial
INVALID_PW_CHAR			EQU -1	; Representa um caractere impossível de estar na senha
WAIT_HASH_CONFIRM		EQU 100	; Valor aleatório só para sinalizar o estado de aguardando # ser pressionado
; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		
PASSWORDS SPACE 8			; 4 bytes para a senha do usuário e 4 bytes para a senha mestra
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
	; R3 usado para instruções e dados do LCD
	; R4 usado para os textos do LCD
	MOV R5, #GET_PASSWORD	; R5 usado para o estado do cofre
	MOV R6, #INVALID_DIGIT	; R6 usado para guardar o dígito lido do teclado
	MOV R7, #0				; R7 usado para contar quantos dígitos o usuário digitou
	LDR R8, =PASSWORDS		; R8 usado para apontar a posição da senha salva na memória
	MOV R9, #INVALID_PW_CHAR; R9 usado para ler os caracteres da senha salva na memória
	STRB R9, [R8]
	MOV R10, #0				; R10 usado para contar quantos dígitos o usuário acertou
	MOV R11, #0				; R11 usado para contar quantos erros de senha aconteceram
	; R12 usado para configurar a senha mestra na memória e como registrador auxiliar
	BL SetMasterPassword
	
	B MainLoop

; Função SetMasterPassword
; Guarda a senha mestra na memória
; Parâmetro de entrada: R8 -> Endereço aonde a senha deve ser armazenada
; Parâmetro de saída: Não tem
SetMasterPassword
	PUSH {LR}
	
	MOV R12, #1				; Primeiro dígito da senha mestra
	STRB R12, [R8, #5]		; Senha mestra é armazenada 4 bytes a frente da senha do usuário
	MOV R12, #2				; Segundo dígito da senha mestra
	STRB R12, [R8, #6]
	MOV R12, #3				; Terceiro dígito da senha mestra
	STRB R12, [R8, #7]
	MOV R12, #4				; Quarto dígito da senha mestra
	STRB R12, [R8, #8]
	MOV R12, #0
	
	POP {LR}
	BX LR

; Função MainLoop
; Loop principal do programa
; Parâmetro de entrada: R5 -> Estado atual do cofre
; Parâmetro de saída: Não tem
MainLoop

	CMP R5, #CLOSED			; Verifica se o cofre já está fechado
	BEQ ClosedFunction
	
	CMP R5, #GET_PASSWORD	; Estado inicial do cofre. Pede a senha para fechá-lo
	BEQ.W GetPassword		; Branch offset out of range (BEQ.W corrige o problema)
	
	CMP R5, #SET_PASSWORD	; Configura a senha que o usuário digitou
	BEQ.W SetPassword		; Branch offset out of range (BEQ.W corrige o problema)
	
	CMP R5, #CLOSING		; Coloca o cofre em processo de fechamento
	BEQ.W ClosingFunction	; Branch offset out of range (BEQ.W corrige o problema)

	B MainLoop

; Funções ClosedFunction e CheckPassword
; Verifica a senha digitada enquanto o cofre está fechado
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
ClosedFunction
	BL LCD_Line2			; Coloca o cursor no começo da segunda linha
	
	LDR R4, =EMPTY_STR		; Imprime uma string vazia na segunda linha
	BL LCD_PrintString
	
	BL LCD_Line2			; Depois do cursor ser deslocado para o fim, posiciona de volta no começo

	MOV R7, #0				; O usuário ainda não inseriu dígitos. Zera o contador
	MOV R10, #0				; O usuário ainda não acertou nenhum dígito. Zera o contador
	MOV R6, #INVALID_DIGIT	; Nenhum dígito foi lido. Coloca R6 em estado inválido (reset)
CheckPassword
	BL MapMatrixKeyboard	; Lê o dígito pressionado no teclado e guarda em R6
	
	LDRB R9, [R8, R7]		; Desloca o ponteiro da senha em R7 bytes, onde R7 é o contador de dígitos inseridos
	
	CMP R6, R9				; Compara o dígito inserido com o dígito da senha salva na memória
	ADDEQ R10, R10, #1		; Incrementa o contador de acertos se o usuário acertou o caractere atual
	
	MOV R6, #INVALID_DIGIT	; Depois de contabilizado, invalida R6 e R9 para evitar erros
	MOV R9, #INVALID_PW_CHAR
	
	CMP R10, #4				; Verifica se o usuário já acertou os 4 dígitos da senha
	BEQ OpenFunction		; Se acertou, abre o cofre
	
	CMP R7, #4				; 4 dígitos já foram inseridos, mas usuário não acertou
	BEQ WrongPassword		; Inseriu uma senha incorreta
	
	B CheckPassword			; Continua lendo os dígitos se ainda está inserindo

; Função WrongPassword
; Mostra mensagem de erro de senha no display e trava o cofre se excedeu o máximo de tentativas
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
WrongPassword
	BL LCD_Reset					; Limpa o display e coloca o cursor em home
	
	LDR R4, =WRONG_PASSWORD_STR		; Imprime mensagem de senha incorreta no display
	BL LCD_PrintString
	
	MOV R0, #1000					; Mostra a mensagem de erro durante 1s
	BL SysTick_Wait1ms
	
	CMP R11, #MAX_PASSWORD_ATTEMPTS	; Verifica se chegou no número máximo de tentativas de senha
	ADDNE R11, R11, #1				; Se não chegou, incrementa o contador
	
	CMP R11, #MAX_PASSWORD_ATTEMPTS	; Se a tentativa atual é o máximo, trava o cofre
	BEQ LockedFunction
	
	MOV R7, #0						; Zera o contador de dígitos inseridos
	
	B ClosedFunction				; Ainda restam tentativas -> Retoma a rotina de verificação de senha

; Funções LockedFunction, MasterPasswordError, WaitPJ0_Interrupt e CheckMasterPassword
; Mostra mensagem de cofre travado com senha mestra e aguarda usuário pressionar PJ0 e inserir senha mestra para destravar
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
LockedFunction
	MOV R5, #LOCKED_MASTER		; Cofre foi travado e precisa da senha mestra para ser destravado
MasterPasswordError
	MOV R6, #INVALID_DIGIT		; Invalida o dígito lido do teclado para evitar erros
	MOV R7, #4					; R7 = 4 para ignorar os primeiros 4 bytes da memória em PASSWORDS (acessar senha mestra)
	MOV R10, #0					; Zera o contador de dígitos acertados
	
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =LOCKED_MASTER_STR	; Mostra a mensagem de erro senha mestra
	BL LCD_PrintString
WaitPJ0_Interrupt
	BL StartBlinkingLEDs		; Chama a rotina que pisca todos os LEDs da placa auxiliar
	CMP R5, #LOCKED				; Verifica se PJ0 foi pressionado para sair do modo travado senha mestra para travado
	BNE WaitPJ0_Interrupt
	BL LCD_Line2				; Coloca o cursor no começo da segunda linha
CheckMasterPassword
	BL MapMatrixKeyboard		; Lê o dígito pressionado no teclado e guarda em R6
	
	LDRB R9, [R8, R7]			; Lê um dígito da senha mestra
	CMP R6, R9					; Compara com o dígito inserido
	ADDEQ R10, R10, #1			; Se estiver certo, incrementa o contador de acertos
	
	MOV R6, #INVALID_DIGIT		; Depois de contabilizado, invalida R6 e R9 para evitar erros
	MOV R9, #INVALID_PW_CHAR
	
	CMP R10, #4					; Verifica se os 4 dígitos corretos foram inseridos
	BEQ UnlockFunction			; Destrava o cofre
	
	CMP R7, #8					; Verifica se já leu 4 dígitos, mas não foram os certos
	BEQ LockedFunction			; Retoma a rotina de pedir interrupção do PJ0 e senha mestra
	
	B CheckMasterPassword		; Se nada disso aconteceu, continua lendo os dígitos

; Função StartBlinkingLEDs
; Pisca todos os LEDs da placa auxiliar
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
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

; Função StopBlinkingLEDs
; Desativa o transistor dos LEDs (para de piscar todos os LEDs da placa auxiliar)
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
StopBlinkingLEDs
	PUSH {LR}
	
	MOV R0, #2_000000			; Desativa o transistor dos LEDs (PP5)
	BL PortP_Output
	
	MOV R0, #1					; Atrasa 1ms
	BL SysTick_Wait1ms
	
	POP {LR}
	BX LR

; Função UnlockFunction
; Para de piscar os LEDs da placa e abre o cofre
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
UnlockFunction
	BL StopBlinkingLEDs			; Para de piscar todos os LEDs da placa auxiliar

	B OpenFunction				; Abre o cofre

; Função OpenFunction
; Zera registradores e coloca o cofre em estado de pedir senha (cofre aberto)
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
OpenFunction
	MOV R5, #GET_PASSWORD		; Coloca o cofre em estado de pedir senha
	MOV R6, #INVALID_DIGIT		; Invalida R6 com valor fora do intervalo
	MOV R7, #0					; Zera o contador de dígitos inseridos
	MOV R10, #0					; Zera o contador de dígitos acertados
	MOV R11, #0					; Zera o contador de erros de senha
	MOV R12, #0					; Zera o registrador auxiliar
	
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =OPENING_STR		; Imprime a mensagem abrindo cofre
	; Esse erro parou de aparecer, então comentei a linha
	;LTORG						; Error: Literal pool too distant, use LTORG to assemble it within 4KB
	BL LCD_PrintString
	
	MOV R0, #5000				; Mostra a mensagem durante 5s
	BL SysTick_Wait1ms
	
	B MainLoop					; Retoma o loop principal

; Função GetPassword
; Mostra a mensagem de inserir nova senha e coloca o cofre em estado de configurar a nova senha
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
GetPassword
	BL LCD_Reset				; Limpa o display e coloca o cursor em home
	
	LDR R4, =OPEN_STR			; Informa que o cofre está aberto na primeira linha do LCD
	BL LCD_PrintString
	
	BL LCD_Line2
	LDR R4, =GET_PASSWORD_STR	; Pede nova senha na segunda linha do LCD
	BL LCD_PrintString
	
	MOV R0, #500				; Mostra a mensagem na segunda linha do LCD durante 0,5s
	BL SysTick_Wait1ms
	
	BL LCD_Line2
	LDR R4, =EMPTY_STR			; Limpa a segunda linha do LCD
	BL LCD_PrintString
	
	BL LCD_Line2				; Coloca o cursor no começo da segunda linha
	
	MOV R5, #SET_PASSWORD		; Coloca o cofre em estado de cadastrar a nova senha
	
	B MainLoop					; Retoma o loop principal no estado de cadastrar a nova senha

; Função SetPassword
; Mostra a mensagem de confirmação de senha usando # e aguarda # ser inserida para avançar para o estado de fechando cofre
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
SetPassword
	BL MapMatrixKeyboard		; Lê o dígito pressionado no teclado e guarda em R6
	
	CMP R12, #WAIT_HASH_CONFIRM	; Flag de 4 dígitos inseridos e aguardando a confirmação com #
	BEQ CheckHashConfirmation
	
	STRB R6, [R8, R7]			; Guarda o dígito inserido na memória sequencialmente
	
	CMP R7, #4					; Verifica se 4 dígitos foram inseridos
	BLT SetPassword				; Se não, retoma o loop para receber o próximo
	
	BL LCD_Reset				; Se sim, limpa o display e coloca o cursor em home
	
	LDR R4, =HASH_CONFIRM_STR	; Imprime a mensagem de confirmação da senha usando #
	BL LCD_PrintString
	
	MOV R12, #WAIT_HASH_CONFIRM	; Flag de 4 dígitos inseridos e aguardando a confirmação com #
CheckHashConfirmation
	CMP R5, #CLOSING			; Verifica se o estado do cofre é fechando (DIGIT_HASH no matrix_keyboard.s altera R5 para CLOSING)
	BNE SetPassword				; Se ainda não for, volta para configurar a senha
	B MainLoop					; Retoma o loop principal

; Função ClosingFunction
; Mostra a mensagem que o cofre está fechando, fecha o cofre e mostra que está fechado
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
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
	
	BL LCD_Line2				; Coloca o cursor no começo da segunda linha
	LDR R4, =ENTER_PASSWORD_STR	; Pede para o usuário inserir a senha na segunda linha do LCD
	BL LCD_PrintString
	
	MOV R0, #1000				; Aguarda 1s antes de mudar o estado do cofre para trancado
	BL SysTick_Wait1ms
	
	MOV R5, #CLOSED				; Coloca o cofre em estado de fechado
	
	B MainLoop					; Retoma o loop principal

; Definição dos textos do LCD com 16 caracteres cada
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
    ALIGN					; Garante que o fim da seção está alinhada 
    END						; Fim do arquivo

#include <stdint.h>
#include <math.h>

#include "uart.h"
#include "tm4c1294ncpdt.h"

#define UARTSysClk 80000000
#define BAUDRATE 57600

void SysTick_Wait1ms(uint32_t delay);

void UART_Init(void)
{
	// 1. Habilitar clock no módulo UART e verificar se está pronta para uso.
	SYSCTL_RCGCUART_R = SYSCTL_RCGCUART_R0;
	
	while ((SYSCTL_PRUART_R & SYSCTL_PRUART_R0) != SYSCTL_PRUART_R0) {
		//
	}
	
	// 2. Garantir que a UART esteja desabilitada antes de fazer as configurações.
	UART0_CTL_R = UART0_CTL_R & (~UART_CTL_UARTEN);
	
	// 3. Escrever o baud-rate nos registradores UARTIBRD e UARTFBRD.
	
	// Verifica se o bit HSE do UART0_CTL_R é 1 ou 0 e define clkDiv como 8 ou 16, respectivamente.
	int clkDiv = ((UART0_CTL_R & 0x20) == 0) ? 16 : 8;	// 0x20 = 2_100000
	float BRD = UARTSysClk/(clkDiv * BAUDRATE);
	
	UART0_IBRD_R = (int) BRD;
	UART0_FBRD_R = (int) round((BRD - (int) BRD) * 64);
	
	// 4. Configurar o registrador UARTLCRH para o número de bits, paridade, stop bits e fila.
	// UARTLCRH: SPS | WLEN | FEN | STP2 | EPS | PEN | BRK
	UART0_LCRH_R = 0x7E; // 2_01111110
	
	// 5. Garantir que a fonte de clock seja o clock do sistema no registrador UARTCC escrevendo 0.
	UART0_CC_R = 0;
	
	// 6. Habilitar as flags RXE, TXE e UARTEN no registrador UARTCTL (habilitar a recepção, transmissão e a UART).
	UART0_CTL_R = (UART_CTL_UARTEN | UART_CTL_TXE | UART_CTL_RXE);
}

unsigned char UART_Receive(void)
{
	unsigned char message = 0;
	unsigned long queueEmpty = (UART0_FR_R & UART_FR_RXFE) >> 4;

	if (!queueEmpty)
	{
		message = UART0_DR_R;
	}

	return message;
};

void UART_Transmit(unsigned char character)
{
	unsigned long queueFull = (UART0_FR_R & UART_FR_TXFF) >> 5;

	if ((!queueFull) && (character != 0))
	{
		UART0_DR_R = character;
	}
	
	SysTick_Wait1ms(10);
};

void UART_SendString(unsigned char* string)
{
	unsigned char character = string[0];
	int i = 1;
	
  while (character != '\0')
	{
		UART_Transmit(character);
		character = string[i++];
	}
};

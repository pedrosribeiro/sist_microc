// gpio.c
// Desenvolvido para a placa EK-TM4C1294XL
// Template by Prof. Guilherme Peron

#include <stdint.h>
#include "tm4c1294ncpdt.h"

// Definições dos Ports
#define GPIO_PORTE (0x00000010)	// SYSCTL_PPGPIO_P4
#define GPIO_PORTF (0x00000020)	// SYSCTL_PPGPIO_P5
#define GPIO_PORTJ (0x00000100)	// SYSCTL_PPGPIO_P8
#define GPIO_PORTK (0x00000200)	// SYSCTL_PPGPIO_P9
#define GPIO_PORTL (0x00000400)	// SYSCTL_PPGPIO_P10
#define GPIO_PORTM (0x00000800)	// SYSCTL_PPGPIO_P11
#define GPIO_PORTP (0x00002000)	// SYSCTL_PPGPIO_P13

// Declarations
void LCD_Reset (void);
void LCD_WriteString (char* str);
void SysTick_Wait1ms(uint32_t delay);

// Global Flags (external)
extern volatile int RESET_FLAG;

// -------------------------------------------------------------------------------
// Função GPIO_Init
// Inicializa os ports E, F, J, K, L, M e P
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void GPIO_Init(void)
{
	// 1. Habilitar o clock no módulo GPIO no registrador RCGGPIO (cada bit representa uma GPIO) e
	// esperar até que a respectiva GPIO esteja pronta para ser acessada no registrador PRGPIO (cada
	// bit representa uma GPIO).
	SYSCTL_RCGCGPIO_R = (GPIO_PORTE | GPIO_PORTF | GPIO_PORTJ | GPIO_PORTK | GPIO_PORTL | GPIO_PORTM | GPIO_PORTP);

  while((SYSCTL_PRGPIO_R & (GPIO_PORTE | GPIO_PORTF | GPIO_PORTJ | GPIO_PORTK | GPIO_PORTL | GPIO_PORTM | GPIO_PORTP) ) != 
													 (GPIO_PORTE | GPIO_PORTF | GPIO_PORTJ | GPIO_PORTK | GPIO_PORTL | GPIO_PORTM | GPIO_PORTP) )
	{
		//
	};
	
	// 2. Desabilitar a funcionalidade analógica no registrador GPIOAMSEL.
	GPIO_PORTE_AHB_AMSEL_R = 0x10;		// 0x10 = 2_10000: PE4 analógica
	GPIO_PORTF_AHB_AMSEL_R = 0x00;
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTK_AMSEL_R = 0x00;
	GPIO_PORTL_AMSEL_R = 0x00;
	GPIO_PORTM_AMSEL_R = 0x00;				
	GPIO_PORTP_AMSEL_R = 0x00;	
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTE_AHB_PCTL_R = 0x00;
	GPIO_PORTF_AHB_PCTL_R = 0x00;
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTK_PCTL_R = 0x00;
	GPIO_PORTL_PCTL_R = 0x00;
	GPIO_PORTM_PCTL_R = 0x00;
	GPIO_PORTP_PCTL_R = 0x00;
															
	// 4. DIR para 0 se for entrada, 1 se for saída
	GPIO_PORTE_AHB_DIR_R = 0x03;			// 0x03 = 2_00000011: PE1 e PE0
	GPIO_PORTF_AHB_DIR_R = 0x04;			// 0x04 = 2_00000100: PF2
	GPIO_PORTJ_AHB_DIR_R = 0x00;			// 0x00 = 2_00000000
	GPIO_PORTK_DIR_R = 0xFF;					// 0xFF = 2_11111111: PK7:PK0
	GPIO_PORTL_DIR_R = 0x00;					// 0x00 = 2_00000000
	GPIO_PORTM_DIR_R = 0xF7;					// 0xF7 = 2_11110111: PM7:PM4 e PM2:PM0
	GPIO_PORTP_DIR_R = 0x02;					// 0x02 = 2_00000010: PP1
		
	// 5. Limpar os bits AFSEL para selecionar GPIO sem função alternativa	
	GPIO_PORTE_AHB_AFSEL_R = 0x10;		// 0x10 = 2_10000: PE4 analógica
	GPIO_PORTF_AHB_AFSEL_R = 0x00;
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTK_AFSEL_R = 0x00;
	GPIO_PORTL_AFSEL_R = 0x00;
	GPIO_PORTM_AFSEL_R = 0x00;
	GPIO_PORTP_AFSEL_R = 0x00;
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTE_AHB_DEN_R = 0x03;		// 0x03 = 2_00000011: PE1 e PE0
	GPIO_PORTF_AHB_DEN_R = 0x04;		// 0x04 = 2_00000100: PF3
	GPIO_PORTJ_AHB_DEN_R = 0x03;		// 0x03 = 2_00000011: PJ1 e PJ0
	GPIO_PORTK_DEN_R = 0xFF;				// 0xFF = 2_11111111: PK7:PK0
	GPIO_PORTL_DEN_R = 0x0F;				// 0x0F = 2_00001111: PL3:PL0
	GPIO_PORTM_DEN_R = 0xF7;				// 0xF7 = 2_11110111: PM7:PM4 e PM2:PM0
	GPIO_PORTP_DEN_R = 0x03;				// 0x03 = 2_00000011: PP1 e PP0
	
	// 7. Habilitar resistor de pull-up interno, setar PUR para 1
	GPIO_PORTJ_AHB_PUR_R = 0x3;		// PJ1 e PJ0
	GPIO_PORTL_PUR_R = 0xF;				// PL3:PL0
	
	// 8. Interrupções
	GPIO_PORTJ_AHB_IM_R		= 0x00;
	GPIO_PORTJ_AHB_IS_R		= 0x00;
	GPIO_PORTJ_AHB_IBE_R	= 0x00;
	GPIO_PORTJ_AHB_IEV_R	= 0x00;
	GPIO_PORTJ_AHB_ICR_R	= 0x01;
	GPIO_PORTJ_AHB_IM_R		= 0x01;
	NVIC_EN1_R						= 0x80000;		// 2_1 << 19
	NVIC_PRI12_R					= 0xA0000000;	// 2_5 << 29
}

// Função PortF_Output
// Escreve na porta F
// Parâmetro de entrada: Valor a ser escrito na porta F
// Parâmetro de saída: Não tem
void PortF_Output (uint32_t data)
{
	// Escrita amigável
	uint32_t temp;
	temp = GPIO_PORTF_AHB_DATA_R & 0xFB;	// Zerar tudo exceto PF2
	temp = temp | data;
	GPIO_PORTF_AHB_DATA_R = temp;
}

// Função PortJ_Input
// Lê  a porta J
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Valor lido na porta J
uint32_t PortJ_Input (void)
{
	return GPIO_PORTJ_AHB_DATA_R;
}

void GPIOPortJ_Handler (void)
{
	RESET_FLAG = 1;			// Raise flag
	TIMER0_CTL_R = 0x0; // Desabilita o timer 0
	PortF_Output(0x00); // Disable L293
	
	// Limpa a flag de interrupção
	int temp;
	temp = 0x1;
	temp |= GPIO_PORTJ_AHB_ICR_R;
	GPIO_PORTJ_AHB_ICR_R = temp;
	
	// Imprime mensagem de reset
	LCD_Reset();
	LCD_WriteString("   Cancelado    ");
	
	// Aguarda 0,5s
	SysTick_Wait1ms(500);
}

// Função PortK_Output
// Escreve na porta K
// Parâmetro de entrada: Valor a ser escrito na porta K
// Parâmetro de saída: Não tem
void PortK_Output (uint32_t data)
{
	// Escrita amigável
	uint32_t temp;
	temp = GPIO_PORTK_DATA_R & 0x00;
	temp = temp | data;
	GPIO_PORTK_DATA_R = temp;
}

// Função PortL_Input
// Lê  a porta L
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Valor lido na porta L
uint32_t PortL_Input (void)
{
	return GPIO_PORTL_DATA_R;
}

// Função PortM_Output
// Escreve na porta M
// Parâmetro de entrada: Valor a ser escrito na porta M
// Parâmetro de saída: Não tem
void PortM_Output (uint32_t data)
{
	// Escrita amigável
	uint32_t temp;
	temp = GPIO_PORTM_DATA_R & 0x08; // Zerar PM2:PM0
	temp = temp | data;
	GPIO_PORTM_DATA_R = temp;
}


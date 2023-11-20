// gpio.c
// Desenvolvido para a placa EK-TM4C1294XL
// Template by Prof. Guilherme Peron

#include <stdint.h>
#include "tm4c1294ncpdt.h"

// Definições dos Ports
#define GPIO_PORTA (0x00000001)	// SYSCTL_PPGPIO_P0
#define GPIO_PORTF (0x00000020)	// SYSCTL_PPGPIO_P5
#define GPIO_PORTH (0x00000080)	// SYSCTL_PPGPIO_P7
#define GPIO_PORTJ (0x00000100)	// SYSCTL_PPGPIO_P8
#define GPIO_PORTN (0x00001000)	// SYSCTL_PPGPIO_P12
#define GPIO_PORTP (0x00002000)	// SYSCTL_PPGPIO_P13
#define GPIO_PORTQ (0x00004000)	// SYSCTL_PPGPIO_P14

// -------------------------------------------------------------------------------
// Função GPIO_Init
// Inicializa os ports A, F, H, J, N, P e Q
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void GPIO_Init(void)
{
	// 1. Habilitar o clock no módulo GPIO no registrador RCGGPIO (cada bit representa uma GPIO) e
	// esperar até que a respectiva GPIO esteja pronta para ser acessada no registrador PRGPIO (cada
	// bit representa uma GPIO).
	SYSCTL_RCGCGPIO_R = (GPIO_PORTA | GPIO_PORTF | GPIO_PORTH | GPIO_PORTJ | GPIO_PORTN | GPIO_PORTP | GPIO_PORTQ);

  while((SYSCTL_PRGPIO_R & (GPIO_PORTA | GPIO_PORTF | GPIO_PORTH | GPIO_PORTJ | GPIO_PORTN | GPIO_PORTP | GPIO_PORTQ) ) != 
													 (GPIO_PORTA | GPIO_PORTF | GPIO_PORTH | GPIO_PORTJ | GPIO_PORTN | GPIO_PORTP | GPIO_PORTQ) )
	{
		//
	};
	
	// 2. Desabilitar a funcionalidade analógica no registrador GPIOAMSEL.
	GPIO_PORTA_AHB_AMSEL_R = 0x00;
	GPIO_PORTF_AHB_AMSEL_R = 0x00;
	GPIO_PORTH_AHB_AMSEL_R = 0x00;
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
	GPIO_PORTP_AMSEL_R = 0x00;
	GPIO_PORTQ_AMSEL_R = 0x00;				
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTA_AHB_PCTL_R = 0x11;				// UART0
	GPIO_PORTF_AHB_PCTL_R = 0x00;
	GPIO_PORTH_AHB_PCTL_R = 0x00;
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTN_PCTL_R = 0x00;
	GPIO_PORTP_PCTL_R = 0x00;
	GPIO_PORTQ_PCTL_R = 0x00;
															
	// 4. DIR para 0 se for entrada, 1 se for saída
	GPIO_PORTA_AHB_DIR_R = 0xF2;				// 11110010	: PA7 ao PA4 e PA1
	GPIO_PORTF_AHB_DIR_R = 0x11;				// 10001		: PF3 ao PF1
	GPIO_PORTH_AHB_DIR_R = 0x0F;				// 1111			: PH3 ao PH0 (driver de potência)
	GPIO_PORTJ_AHB_DIR_R = 0x00;				// 00				: PJ0
	GPIO_PORTN_DIR_R = 0x03;						// 11				: PN1 ao PN0
	GPIO_PORTP_DIR_R = 0x20;						// 100000		: PP5
	GPIO_PORTQ_DIR_R = 0x0F;						// 1111			: PQ3 ao PQ0
		
	// 5. Limpar os bits AFSEL para selecionar GPIO sem função alternativa	
	GPIO_PORTA_AHB_AFSEL_R = 0x03;			// UART
	GPIO_PORTF_AHB_AFSEL_R = 0x00;
	GPIO_PORTH_AHB_AFSEL_R = 0x00;
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTN_AFSEL_R = 0x00;
	GPIO_PORTP_AFSEL_R = 0x00;
	GPIO_PORTQ_AFSEL_R = 0x00;
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTA_AHB_DEN_R = 0xF3;				// 11110011	: PA7 ao PA4 e PA1 ao PA0
	GPIO_PORTF_AHB_DEN_R = 0x11;				// 10001		: PF3 ao PF1
	GPIO_PORTH_AHB_DEN_R = 0x0F;				// 1111			: PH3 ao PH0 (driver de potência)
	GPIO_PORTJ_AHB_DEN_R = 0x01;				// 1				: PJ0
	GPIO_PORTN_DEN_R = 0x03;						// 11				: PN1 ao PN0
	GPIO_PORTP_DEN_R = 0x20;						// 100000		: PP5
	GPIO_PORTQ_DEN_R = 0x0F;						// 1111			: PQ3 ao PQ0
	
	// 7. Habilitar resistor de pull-up interno, setar PUR para 1
	GPIO_PORTJ_AHB_PUR_R = 0x01;				// PJ0
	
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

void GPIOPortJ_Handler(void)
{
	//
}

void PortH_Output(uint32_t degrees)
{
	uint32_t temp;
	temp = GPIO_PORTH_AHB_DATA_R & 0x00;	// escrita amigável
	
	temp = temp | degrees;
	
	GPIO_PORTH_AHB_DATA_R = temp;
}

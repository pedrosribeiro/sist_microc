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
}

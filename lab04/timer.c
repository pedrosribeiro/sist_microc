// timer.c

#include <stdint.h>

#include "tm4c1294ncpdt.h"

// Declarations
void PortF_Output (uint32_t data);

// Global Flags (external)
extern int PWM_HIGH;
extern int PWM_STATE;

// Função Timer_Init
// Inicializa o Timer 0
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void Timer_Init(void)
{
	// 1. Habilitar o clock do timer 0 e esperar até estar pronto para uso.
	SYSCTL_RCGCTIMER_R |= 0x1;
	
	while((SYSCTL_PRTIMER_R & 0x1) != 0x1)
	{
		//
	}
	
	// 2. Desabilita o timer 0 para configuração
	TIMER0_CTL_R &= 0x0;
	
	// 3. Configuração do timer 0
	TIMER0_CFG_R |= 0x00;				// Quantos bits será a contagem do temporizador (32 bits: 0x00)
	TIMER0_TAMR_R |= 0x2;				// Modo de operação do timer (0x02: Periódico)
	TIMER0_TAILR_R = PWM_HIGH;	// Valor da contagem
	TIMER0_ICR_R  |= 0x1;				// Limpa a flag de interrupção do timer
	TIMER0_IMR_R |= 0x1;				// Habilita a interrupção do timer
	NVIC_PRI4_R |= 3 << 29;			// Seta prioridade 3 para a interrupção
	NVIC_EN0_R |= 1 << 19;			// Habilita a interrupção do timer no NVIC
	
	// 4. Habilita o timer 0 após a configuração
	TIMER0_CTL_R |= 0x1;
}

void Timer0A_Handler()
{
	TIMER0_ICR_R  |= 0x1;				// Limpa a flag de interrupção do timer 0
	
	if (PWM_STATE == 1)					// Alto
	{
		PWM_STATE = 0;
		PortF_Output(0x00);
		TIMER0_TAILR_R = 80000 - PWM_HIGH;
	}
	else												// Baixo
	{
		PortF_Output(0x04);
		TIMER0_TAILR_R = PWM_HIGH;
		PWM_STATE = 1;
	}
}

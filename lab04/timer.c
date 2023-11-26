// timer.c

#include <stdint.h>

#include "tm4c1294ncpdt.h"

// Declarations
void PortF_Output (uint32_t data);

// Global Flags (external)
extern int PWM_HIGH;
extern int PWM_STATE;

// Fun��o Timer_Init
// Inicializa o Timer 0
// Par�metro de entrada: N�o tem
// Par�metro de sa�da: N�o tem
void Timer_Init(void)
{
	// 1. Habilitar o clock do timer 0 e esperar at� estar pronto para uso.
	SYSCTL_RCGCTIMER_R |= 0x1;
	
	while((SYSCTL_PRTIMER_R & 0x1) != 0x1)
	{
		//
	}
	
	// 2. Desabilita o timer 0 para configura��o
	TIMER0_CTL_R &= 0x0;
	
	// 3. Configura��o do timer 0
	TIMER0_CFG_R |= 0x00;				// Quantos bits ser� a contagem do temporizador (32 bits: 0x00)
	TIMER0_TAMR_R |= 0x2;				// Modo de opera��o do timer (0x02: Peri�dico)
	TIMER0_TAILR_R = PWM_HIGH;	// Valor da contagem
	TIMER0_ICR_R  |= 0x1;				// Limpa a flag de interrup��o do timer
	TIMER0_IMR_R |= 0x1;				// Habilita a interrup��o do timer
	NVIC_PRI4_R |= 3 << 29;			// Seta prioridade 3 para a interrup��o
	NVIC_EN0_R |= 1 << 19;			// Habilita a interrup��o do timer no NVIC
	
	// 4. Habilita o timer 0 ap�s a configura��o
	TIMER0_CTL_R |= 0x1;
}

void Timer0A_Handler()
{
	TIMER0_ICR_R  |= 0x1;				// Limpa a flag de interrup��o do timer 0
	
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

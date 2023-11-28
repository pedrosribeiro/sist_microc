// pwm.c

#include <stdint.h>

#include "tm4c1294ncpdt.h"

// Declarations
void PortE_Output (uint32_t data);

// Global Flags (external)
extern int PWM_HIGH;
extern volatile int DIRECTION_FLAG;
extern int MOTOR_ACTIVE;

void PWM (int duty_cycle)
{
	if (DIRECTION_FLAG == 1)	// Horário
	{
		PortE_Output(0x02);
	}
	else											// Anti-horário
	{
		PortE_Output(0x01);
	}
	
	PWM_HIGH = 80000 * duty_cycle/100;
	
	if (MOTOR_ACTIVE == 0)
	{
		TIMER0_CTL_R |= 0x1;		// Habilita o timer 0
		MOTOR_ACTIVE = 1;				// Ativa o motor
	}
	
}

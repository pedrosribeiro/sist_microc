#include <stdint.h>

#include "stepper_motor.h"
#include "tm4c1294ncpdt.h"

void SysTick_Wait1ms(uint32_t delay);
void PortH_Output(uint32_t degrees);

void Stepper_Motor_Init(void)
{
	PortH_Output(0);
}

void Control_Stepper_Motor(uint32_t direction, uint32_t stepMode) 
{
	//
}

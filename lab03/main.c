// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Template by Prof. Guilherme Peron

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "gpio.h"
#include "uart.h"
#include "stepper_motor.h"

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void SysTick_Wait1us(uint32_t delay);
void GPIO_Init(void);

void Rotate(void)
{
	//
}

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	UART_Init();
	LEDs_Timer_Init();
	
	while (1)
	{
		Stepper_Motor_Init();
		Reset_LEDs();
		Control_Stepper_Motor(0, 0);
		Rotate();	// ainda não implementei
		
		return 0;
	}
}

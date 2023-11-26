// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Template by Prof. Guilherme Peron

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "gpio.h"
#include "ad_converter.h"
#include "lcd.h"
#include "timer.h"

typedef enum MotorState
{
	StoppedState,
  SelectingState,
  UsingKeyboardState,
  UsingPotentiometerState,
} MotorStates;

// Declarations
void PLL_Init(void);
void SysTick_Init(void);
void Process_State (MotorStates states);

// Global Flags
int PWM_HIGH;
int PWM_STATE = 0;
int MOTOR_ACTIVE = 0;
volatile int RESET_FLAG = 0;
volatile int DIRECTION_FLAG = 0;

// Função Main
// Loop principal
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	AD_Converter_Init();
	LCD_Init();
	Timer_Init();
	Process_State(StoppedState);
	
	return 0;
}

void Process_State (MotorStates states)
{
	while (1)
	{
		if (RESET_FLAG == 1)	// Reseta flags e variáveis
		{
			RESET_FLAG = 0;
			PWM_STATE = 0;
			DIRECTION_FLAG = 0;
			MOTOR_ACTIVE = 0;
			states = StoppedState;
		}
		
		switch (states)
		{
			case StoppedState:
				LCD_Reset();
				LCD_WriteString("Motor parado    ");
				LCD_Line2();
				LCD_WriteString("Press any key   ");
				break;
			
			case SelectingState:
				//
				break;
			
			case UsingKeyboardState:
				//
				break;
			
			case UsingPotentiometerState:
				//
				break;
		}
	}
}

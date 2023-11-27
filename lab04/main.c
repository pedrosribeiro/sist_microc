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
#include "matrix_keyboard.h"

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
void SysTick_Wait1ms(uint32_t delay);
void Process_State (MotorStates states);

// Global Flags
int PWM_HIGH;
int PWM_STATE = 0;
int MOTOR_ACTIVE = 0;
volatile int RESET_FLAG = 0;
volatile int DIRECTION_FLAG = 0;

// Fun��o Main
// Loop principal
// Par�metro de entrada: N�o tem
// Par�metro de sa�da: N�o tem
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
	int key = 0xFF;
	
	while (1)
	{
		if (RESET_FLAG == 1)	// Reseta flags e vari�veis
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
			
				while (key == 0xFF && RESET_FLAG == 0)	// Mant�m o loop enquanto nenhuma tecla for pressionada
				{
					key = MatrixKeyboard_Map();						// L� o teclado
				}
				
				states = SelectingState;								// Troca de estado
				SysTick_Wait1ms(100);										// Aguarda 1s antes de ir para o outro estado
			
				break;
			
			case SelectingState:
				LCD_Reset();
				LCD_WriteString("1. Modo teclado ");
				LCD_Line2();
				LCD_WriteString("2. Modo potencio");
			
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

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
	int key = 0xFF;
	
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
			
				while (key == 0xFF)							// Mantém o loop enquanto nenhuma tecla for pressionada
				{
					key = MatrixKeyboard_Map();		// Lê o teclado
				}
				
				states = SelectingState;				// Troca de estado
				SysTick_Wait1ms(100);						// Aguarda 1s antes de ir para o outro estado
			
				break;
			
			case SelectingState:
				LCD_Reset();
				LCD_WriteString("1. Modo teclado ");
				LCD_Line2();
				LCD_WriteString("2. Modo potencio");
			
				key = 0xFF;
			
				// Mantém o loop enquanto a tecla pressionada não for 1 ou 2
				// 0xEE = 2_11101110, 0xDE = 2_11011110
				while (key != 0xEE && key != 0xDE)
				{
					key = MatrixKeyboard_Map();		// Lê o teclado
				}
				
				if (key == 0xEE) 								// Tecla 1
				{
					states = UsingKeyboardState;
				} else													// Tecla 2
				{
					states = UsingPotentiometerState;
				}
				
				SysTick_Wait1ms(100);						// Aguarda 1s antes de ir para o outro estado
			
				break;
			
			case UsingKeyboardState:
				LCD_Reset();
				LCD_WriteString("Modo teclado    ");
				LCD_Line2();
				LCD_WriteString("selecionado     ");
			
				while (1)
				{
					//
				}
			
				break;
			
			case UsingPotentiometerState:
				LCD_Reset();
				LCD_WriteString("Modo potenciomet");
				LCD_Line2();
				LCD_WriteString("ro selecionado  ");
			
				while (1)
				{
					//
				}
			
				break;
		}
	}
}

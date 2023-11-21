#include <stdint.h>

#include "stepper_motor.h"
#include "tm4c1294ncpdt.h"

void SysTick_Wait1ms(uint32_t delay);
void PortH_Output(uint32_t degrees);

// Função Stepper_Motor_Init
// Inicializa o motor zerando as fases
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void Stepper_Motor_Init(void)
{
	PortH_Output(0);
}

// Função Control_Stepper_Motor
// Controla o motor de passo
// Parâmetro de entrada: Sentido de rotação e passo
// Parâmetro de saída: Não tem
void Control_Stepper_Motor(uint32_t direction, uint32_t stepMode) 
{
	for (int i = 0; i < 22; i++)
	{
		if (stepMode == '0')			// passo-completo
		{
			if (direction == '0')	// horário
			{
				PortH_Output(0xE);		// 1110
				SysTick_Wait1ms(10);
				
				PortH_Output(0xD);		// 1101
				SysTick_Wait1ms(10);
				
				PortH_Output(0xB);		// 1011
				SysTick_Wait1ms(10);
				
				PortH_Output(0x7);		// 0111
				SysTick_Wait1ms(10);
			} else if (direction == '1') // anti-horário
			{
				PortH_Output(0x8);		// 1000
				SysTick_Wait1ms(10);
				
				PortH_Output(0x4);		// 0100
				SysTick_Wait1ms(10);
				
				PortH_Output(0x2);		// 0010
				SysTick_Wait1ms(10);
				
				PortH_Output(0x1);		// 0001
				SysTick_Wait1ms(10);
			}
		} else if (stepMode == '1') // meio-passo
		{
			if (direction == '0')	// horário
			{
				PortH_Output(0xE);		// 1110
				SysTick_Wait1ms(10);
				PortH_Output(0xC);		// 1100
				SysTick_Wait1ms(10);
				
				PortH_Output(0xD);		// 1101
				SysTick_Wait1ms(10);
				PortH_Output(0x9);		// 1001
				SysTick_Wait1ms(10);
				
				PortH_Output(0xB);		// 1011
				SysTick_Wait1ms(10);
				PortH_Output(0x3);		// 0011
				SysTick_Wait1ms(10);
				
				PortH_Output(0x7);		// 0111
				SysTick_Wait1ms(10);
				PortH_Output(0x6);		// 0110
				SysTick_Wait1ms(10);
			} else if (direction == '1') // anti-horário
			{
				PortH_Output(0x6); 		// 0110
				SysTick_Wait1ms(10);
        PortH_Output(0x7); 		// 0111
        SysTick_Wait1ms(10);

        PortH_Output(0x3); 		// 0011
        SysTick_Wait1ms(10);
        PortH_Output(0xB); 		// 1011
        SysTick_Wait1ms(10);

        PortH_Output(0x9); 		// 1001
        SysTick_Wait1ms(10);
        PortH_Output(0xD); 		// 1101
        SysTick_Wait1ms(10);

        PortH_Output(0xC); 		// 1100
        SysTick_Wait1ms(10);
        PortH_Output(0xE); 		// 1110
        SysTick_Wait1ms(10);
			}
		}
	}
}

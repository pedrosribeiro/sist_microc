// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Template by Prof. Guilherme Peron

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "gpio.h"

// Declarations
void PLL_Init(void);
void SysTick_Init(void);

// Fun��o Main
// Loop principal
// Par�metro de entrada: N�o tem
// Par�metro de sa�da: N�o tem
int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	
	return 0;
}

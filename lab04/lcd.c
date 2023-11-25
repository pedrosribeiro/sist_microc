// lcd.c

#include <stdint.h>
#include <string.h>

// Declarations
void SysTick_Wait1ms(uint32_t delay);
uint32_t PortL_Input (void);
void PortK_Output (uint32_t data);
void PortM_Output (uint32_t data);

void LCD_Init (void)
{
	//
}

void LCD_Reset (void)
{
	//
}

void LCD_WriteChar (uint32_t data)
{
	//
}

void LCD_WriteString (char* data)
{
	//
}

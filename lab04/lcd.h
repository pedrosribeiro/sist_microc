// lcd.h

#include <stdint.h>

void LCD_Init (void);
void LCD_Reset (void);
void LCD_WriteChar (uint32_t data);
void LCD_WriteString (char* data);
// lcd.h

#include <stdint.h>

void LCD_Init (void);
void LCD_Instruction (uint32_t inst);
void LCD_Data (uint32_t data);
void LCD_Reset (void);
void LCD_Line2 (void);
void LCD_WriteString (char* str);

// pwm.c

#include <stdint.h>

#include "tm4c1294ncpdt.h"

// Declarations
void PortE_Output (uint32_t data);
void LCD_WriteString (char* str);
void LCD_Reset(void);

// Global Flags (external)
extern int PWM_HIGH;
extern volatile int DIRECTION_FLAG;
extern int MOTOR_ACTIVE;

void PWM (int duty_cycle)
{
	PWM_HIGH = 80000 * duty_cycle/4096;
	
	LCD_Reset();
	
	if (PWM_HIGH < 8000) {LCD_WriteString("10% velocidade ");}
	else if (PWM_HIGH < 16000) {LCD_WriteString("20% velocidade ");}
	else if (PWM_HIGH < 24000) {LCD_WriteString("30% velocidade ");}
	else if (PWM_HIGH < 32000) {LCD_WriteString("40% velocidade ");}
	else if (PWM_HIGH < 40000) {LCD_WriteString("50% velocidade ");}
	else if (PWM_HIGH < 48000) {LCD_WriteString("60% velocidade ");}
	else if (PWM_HIGH < 56000) {LCD_WriteString("70% velocidade ");}
	else if (PWM_HIGH < 64000) {LCD_WriteString("80% velocidade ");}
	else if (PWM_HIGH < 72000) {LCD_WriteString("90% velocidade ");}
	else {LCD_WriteString("100% velocidade ");}
	
}

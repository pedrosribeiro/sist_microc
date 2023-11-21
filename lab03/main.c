// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Template by Prof. Guilherme Peron

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "gpio.h"
#include "uart.h"
#include "stepper_motor.h"

// Declarations
void PLL_Init(void);
void SysTick_Init(void);

// Messages
unsigned char waitMsg[]					= "Aguarde...\n";
unsigned char breakLine[]				= "\n\r";
unsigned char space							= ' ';
unsigned char endMsg[]					= "Fim. Pressione * para recomeçar\n";
unsigned char getSpeedMsg[] 		= "Velocidade (0 ou 1): ";
unsigned char getDirectionMsg[] = "Direção (0 ou 1): ";
unsigned char getAngleMsg[]			= "Ângulo (0 a 360)";

// Global Flags
int stepperMotorActive = 0;
int currentAngle = 0;
int stopRotating = 0;

unsigned char getSpeed(void)
{
	UART_SendString(getSpeedMsg);
	
	unsigned char message = 0;
	while (message == 0x0)
	{
		message = UART_Receive();
		UART_Transmit(message);
	}
	
	UART_SendString(breakLine);
	
	return (message);
}

unsigned char getDirection(void)
{
	UART_SendString(getDirectionMsg);
	
	unsigned char message = 0;
	while (message == 0x0)
	{
		message = UART_Receive();
		UART_Transmit(message);
	}
	
	UART_SendString(breakLine);
	
	return (message);
}

unsigned char* getAngle(void)
{
	UART_SendString(getAngleMsg);
	
	unsigned char message = 0;
	unsigned char* angle;
	
	int i = 0;
	
	while(message != ' ')
	{
		message = UART_Receive();
		if (message != 0 && message != ' ')
		{
			UART_Transmit(message);
			angle[i] = message;
			
			i++;
			message = 0;
		}
	}
	
	angle[i] = '\0';
	UART_SendString(breakLine);
	
	return (angle);
}

// ASCII to Integer Function
uint32_t ATOI(unsigned char* string)
{
	uint32_t result = 0;
	int i = 0;
	
	while (string[i] != '\0')
	{
		int digit = string[i] - '0';
		
		if (digit >= 0 && digit <= 9)
		{
			result = result * 10 + digit;
		}
		else
		{
			break;
		}
		
		i++;
	}
	
	return result;
}

void PrintTerminal(uint32_t angle, unsigned char speed, unsigned char direction)
{
	// uint32_t angle to unsigned char
	uint32_t c = angle/100;						// centenary
	uint32_t t = (angle - c*100)/10;	// tens
	uint32_t u = angle % 10;					// unit
	
	unsigned char angleVector[4];
	
	angleVector[0] = c + 0x30;
	angleVector[1] = t + 0x30;
	angleVector[2] = u + 0x30;
	angleVector[3] = '\0';
	
	UART_Transmit(speed);
	UART_Transmit(space);
	
	UART_Transmit(direction);
	UART_Transmit(space);
	
	UART_SendString(angleVector);
	UART_SendString(breakLine);
}

void WaitForChar(char character)
{
	while (UART_Receive() != character)
	{
		//
	}
}

void Rotate(void)
{
	unsigned char speed = getSpeed();
	unsigned char direction = getDirection();
	unsigned char* angle = getAngle();
	
	uint32_t angleATOI = ATOI(angle);
	
	stepperMotorActive = 1;
	
	for (currentAngle = 0; currentAngle < angleATOI && stopRotating == 0; currentAngle += 15) // incrementa o ângulo de 15 em 15 graus
	{
		UART_SendString(waitMsg);
		UART_SendString(breakLine);
		
		Control_Stepper_Motor(direction, speed); // rotaciona
		LEDs_Output(direction);
		PrintTerminal(currentAngle, speed, direction);
	}
	
	LEDs_Output(direction);
	UART_SendString(waitMsg);
	UART_SendString(breakLine);
	PrintTerminal(currentAngle, speed, direction);

	stepperMotorActive = 0;
	UART_SendString(endMsg);
	UART_SendString(breakLine);
	
	WaitForChar('*');
	
	Stepper_Motor_Init();
	Reset_LEDs();
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
		Rotate();	// incompleta
		
		return 0;
	}
}

// lcd.c

#include <stdint.h>
#include <string.h>

// Declarations
void SysTick_Wait1ms(uint32_t delay);
uint32_t PortL_Input (void);
void PortK_Output (uint32_t data);
void PortM_Output (uint32_t data);

void LCD_Instruction (uint32_t inst);

// Função LCD_Init
// Inicializa o LCD
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void LCD_Init (void)
{
	LCD_Instruction(0x38);	// Inicializar no modo 2 linhas/caracter matriz 5x7
	LCD_Instruction(0x06);	// Cursor com autoincremento para direita
	LCD_Instruction(0x0E);	// Configurar o cursor (habilitar o display + cursor + não-pisca)
	LCD_Instruction(0x01);	// Resetar: Limpar o display e levar o cursor para o home
}

// Função LCD_Instruction
// Escreve no barramento de dados no modo instrução
// Parâmetro de entrada: Instrução a ser escrita
// Parâmetro de saída: Não tem
void LCD_Instruction (uint32_t inst)
{
	PortM_Output(0x04); 	// Ativa o modo de instrução (EN=1, RW=0, RS=0)
	
	PortK_Output(inst);		// Instrução
	SysTick_Wait1ms(10); 	// Delay de 10ms para executar
	
	PortM_Output(0x00);		// Desativa o modo de instrução (EN=0, RW=0, RS=0)
}

// Função LCD_Data
// Escreve no barramento de dados no modo de dados
// Parâmetro de entrada: Dado a ser escrito
// Parâmetro de saída: Não tem
void LCD_Data (uint32_t data)
{
	PortM_Output(0x05); 	// Ativa o modo de dados (EN=1, RW=0, RS=1)
	
	PortK_Output(data);		// Dado
	SysTick_Wait1ms(10); 	// Delay de 10ms para executar
	
	PortM_Output(0x00);		// Desativa o modo de dados (EN=0, RW=0, RS=0)
}

// Função LCD_Reset
// Limpa o display e leva o cursor para o home
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void LCD_Reset (void)
{
	LCD_Instruction(0x01);	// Resetar: Limpar o display e levar o cursor para o home
}

// Função LCD_Line2
// Coloca o cursor no endereço da primeira posição - Segunda Linha
// Parâmetro de entrada: Não tem
// Parâmetro de saída: Não tem
void LCD_Line2 (void)
{
	LCD_Instruction(0xC0);	// Endereço da primeira posição - Segunda Linha
}

// Função LCD_WriteString
// Imprime uma string no LCD através de um loop
// Parâmetro de entrada: String a ser escrita
// Parâmetro de saída: Não tem
void LCD_WriteString (char* str)
{
	for (int i = 0; i < strlen(str); i++)
	{
		LCD_Data(str[i]);
	}
}

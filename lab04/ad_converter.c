// ad_converter.c

#include <stdint.h>

#include "tm4c1294ncpdt.h"

// Função AD_Converter_Init
// Configura o módulo de conversão AD
// Parâmetro de entrada: Não tem
// Parâmetro de saída: O valor convertido
void AD_Converter_Init (void)
{
	// Habilita o clock na porta
	SYSCTL_RCGCADC_R = SYSCTL_RCGCADC_R0;
	
	// Aguarda até que esteja pronta para uso
	while((SYSCTL_PRADC_R & SYSCTL_RCGCADC_R0 ) != SYSCTL_RCGCADC_R0)
	{
		//
	};
	
	// Configurações do conversor
	ADC0_PC_R =  0x07;
	ADC0_ACTSS_R &= ~0x00000800;
	ADC0_EMUX_R &= 0x0FFF;
	ADC0_SSMUX3_R = 0x9;
	ADC0_SSCTL3_R = 0x0006;
	ADC0_ACTSS_R = 0x0008;
}

// Função AD_Convert
// Realiza uma conversão analógio-digital (AD) 
// Parâmetro de entrada: Não tem
// Parâmetro de saída: O valor convertido
uint16_t AD_Convert (void)
{
	uint16_t temp = 0x0FFF;
	
	// Configura o Registrador de Início Sequencial do ADC
	ADC0_PSSI_R = 0x08;
	
	// Aguarda até que esteja pronto para uso
	while ((ADC0_RIS_R & 0x08) != 0x08)
	{
		//
	}
	
	// Lê o resultado da conversão
	temp &= ADC0_SSFIFO3_R;
	
	// Limpa o bit de interrupção associado à conclusão da conversão
	ADC0_ISC_R = 0x08;
	
	return temp;
}

#include <stdint.h>

void GPIO_Init(void);
void LEDs_Timer_Init(void);
void Reset_LEDs(void);
void GPIOPortJ_Handler(void);
void PortH_Output(uint32_t degrees);

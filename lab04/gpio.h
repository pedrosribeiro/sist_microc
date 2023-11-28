// gpio.h

#include <stdint.h>

void GPIO_Init(void);
void PortF_Output (uint32_t data);
void PortE_Output (uint32_t data);
uint32_t PortL_Input (void);
void PortK_Output (uint32_t data);
void PortM_Output (uint32_t data);

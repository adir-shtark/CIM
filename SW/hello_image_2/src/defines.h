/* Manually added definitions for Image Processing Pipeline */

// 1. Interrupt Controller (GIC)
#ifndef XPAR_SCUGIC_0_DEVICE_ID
#define XPAR_SCUGIC_0_DEVICE_ID          0
#endif

// 2. Image Processing IP Interrupt (Mapping to IRQ_F2P[0])
// Hardware ID 61 is usually the first fabric interrupt
#define XPAR_FABRIC_IMAGEPROCESS_0_O_INTR_INTR    61

// 3. DMA S2MM Interrupt (Mapping to IRQ_F2P[1])
// Since your DMA hex was 0x401e, it maps to ID 62
#define XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR   62

// 4. UART 1 (Fixing the tutorial mismatch)
// Your hardware has UART 0, but the code looks for UART 1
#define XPAR_PS7_UART_1_DEVICE_ID        0 

// 5. DMA Base Address (Double check this matches your previous snippet)
#ifndef XPAR_AXI_DMA_0_BASEADDR
#define XPAR_AXI_DMA_0_BASEADDR          0x40400000
#endif
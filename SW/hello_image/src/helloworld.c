#include "xaxidma.h"      // Driver for the Direct Memory Access (The mover)
#include "xparameters.h"  // Hardware addresses (The map)
#include "sleep.h"        // Timing functions
#include "xil_cache.h"    // Cache management (Ensures RAM and CPU see the same data)
#include "xil_io.h"       // Low-level Input/Output
#include "xscugic.h"      // Driver for the Interrupt Controller (The "Switchboard")
#include "imageData.h"    // The actual image data array
#include "xuartps.h"      // Driver for sending data to your PC screen
#include "defines.h"

#define imageSize 512*512 // The total number of pixels in your image

// Function prototype: Checks if the DMA is currently busy or idle
u32 checkIdle(u32 baseAddress,u32 offset);

// --- GLOBAL VARIABLES (Accessible by both Main and Interrupts) ---
XScuGic IntcInstance;     // The "Switchboard" object that manages all hardware signals
static void imageProcISR(void *CallBackRef); // Function that runs when the IP needs data
static void dmaReceiveISR(void *CallBackRef); // Function that runs when the process is 100% done
int done;                 // A simple 0 or 1 flag to tell the Main loop when to stop waiting

int main(){
    u32 status;
    u32 totalTransmittedBytes=0;
    u32 transmittedBytes = 0;
    XUartPs_Config *myUartConfig;
    XUartPs myUart;

    // --- UART SETUP ---
    // (Standard setup to allow the processor to talk to your computer terminal)
    myUartConfig = XUartPs_LookupConfig(XPAR_PS7_UART_1_DEVICE_ID);
    status = XUartPs_CfgInitialize(&myUart, myUartConfig, myUartConfig->BaseAddress);
    XUartPs_SetBaudRate(&myUart, 115200);

    // --- DMA SETUP ---
    XAxiDma_Config *myDmaConfig;
    XAxiDma myDma;
    myDmaConfig = XAxiDma_LookupConfig(XPAR_AXI_DMA_0_BASEADDR);
    status = XAxiDma_CfgInitialize(&myDma, myDmaConfig);

    // DIFFERENT: This line tells the DMA: "When you finish receiving data, 
    // fire an interrupt signal (IOC - Interrupt On Completion)."
    XAxiDma_IntrEnable(&myDma, XAXIDMA_IRQ_IOC_MASK, XAXIDMA_DEVICE_TO_DMA);

    // --- INTERRUPT CONTROLLER (GIC) SETUP ---
    // This section is like setting up a phone switchboard. 
    // You are telling the CPU which "phone number" (ID) belongs to which "department" (ISR).
    XScuGic_Config *IntcConfig;
    IntcConfig = XScuGic_LookupConfig(XPAR_XSCUGIC_NUM_INSTANCES);
    XScuGic_CfgInitialize(&IntcInstance, IntcConfig, IntcConfig->CpuBaseAddress);

    // DIFFERENT: Connect the "Image Process IP" signal to the 'imageProcISR' function.
    // 0xA0 is the priority; 3 is the trigger type (Edge/Level).
    XScuGic_SetPriorityTriggerType(&IntcInstance,XPAR_FABRIC_IMAGEPROCESS_0_O_INTR_INTR,0xA0,3);
    XScuGic_Connect(&IntcInstance,XPAR_FABRIC_IMAGEPROCESS_0_O_INTR_INTR,(Xil_InterruptHandler)imageProcISR,(void *)&myDma);
    XScuGic_Enable(&IntcInstance,XPAR_FABRIC_IMAGEPROCESS_0_O_INTR_INTR);

    // DIFFERENT: Connect the "DMA Finished" signal to the 'dmaReceiveISR' function.
    XScuGic_SetPriorityTriggerType(&IntcInstance,XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR,0xA1,3);
    XScuGic_Connect(&IntcInstance,XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR,(Xil_InterruptHandler)dmaReceiveISR,(void *)&myDma);
    XScuGic_Enable(&IntcInstance,XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR);

    // DIFFERENT: These three lines turn on the "Master Switch" for interrupts on the CPU.
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,(Xil_ExceptionHandler)XScuGic_InterruptHandler,(void *)&IntcInstance);
    Xil_ExceptionEnable();

    // --- STARTING THE PROCESS ---
    // 1. Tell the DMA to prepare to receive the full finished image (512x512).
    status = XAxiDma_SimpleTransfer(&myDma,(UINTPTR)imageData, 512*512,XAXIDMA_DEVICE_TO_DMA);
    
    // 2. DIFFERENT: "Priming the Pump." 
    // Instead of sending the whole image, we only send the first 4 rows.
    // This fills the hardware's internal "pipeline" so it can start working.
    status = XAxiDma_SimpleTransfer(&myDma,(UINTPTR)imageData, 4*512,XAXIDMA_DMA_TO_DEVICE);

    // DIFFERENT: The CPU now sits here doing nothing. 
    // The actual work of sending the rest of the image is handled by the Interrupts below.
    while(!done){
        // The code stays here until 'done' becomes 1 inside the 'dmaReceiveISR' function.
    }

    // --- OUTPUT ---
    // Once everything is finished, send the results to the UART (your PC).
    while(totalTransmittedBytes < imageSize){
        transmittedBytes =  XUartPs_Send(&myUart,(u8*)&imageData[totalTransmittedBytes],1);
        totalTransmittedBytes += transmittedBytes;
        usleep(1000);
    }
}

// --- THE INTERRUPT SERVICE ROUTINES (ISRs) ---

// This function runs every time the Hardware IP is ready for a new row of data.
static void imageProcISR(void *CallBackRef){
    static int i=4; // Keeps track of which row we are on. Starts at 4 because 0-3 are sent in main.
    int status;
    
    // Temporarily turn off this interrupt so we don't get interrupted while processing.
    XScuGic_Disable(&IntcInstance,XPAR_FABRIC_IMAGEPROCESS_0_O_INTR_INTR);
    
    // Wait for the DMA hardware to be ready to accept a new command.
    status = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
    while(status == 0)
        status = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);

    // If we haven't reached the end of the image yet (512 rows + some padding):
    if(i<514){
        // Send exactly ONE row (512 pixels) to the hardware.
        status = XAxiDma_SimpleTransfer((XAxiDma *)CallBackRef,(UINTPTR)&imageData[i*512],512,XAXIDMA_DMA_TO_DEVICE);
        i++; // Move to the next row for next time.
    }
    
    // Turn the interrupt back on so the hardware can call us for the next row.
    XScuGic_Enable(&IntcInstance,XPAR_FABRIC_IMAGEPROCESS_0_O_INTR_INTR);
}

// This function runs ONLY when the very last byte of the 512x512 image is received.
static void dmaReceiveISR(void *CallBackRef){
    // Clear the interrupt signals so they don't fire repeatedly.
    XAxiDma_IntrDisable((XAxiDma *)CallBackRef, XAXIDMA_IRQ_IOC_MASK, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrAckIrq((XAxiDma *)CallBackRef, XAXIDMA_IRQ_IOC_MASK, XAXIDMA_DEVICE_TO_DMA);
    
    // THE IMPORTANT PART: This releases the 'while(!done)' loop in the Main function.
    done = 1; 
    
    XAxiDma_IntrEnable((XAxiDma *)CallBackRef, XAXIDMA_IRQ_IOC_MASK, XAXIDMA_DEVICE_TO_DMA);
}
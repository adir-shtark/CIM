//`timescale 1ns / 1ps // Defines time unit (1ns) and precision (1ps) for simulation

//module lineBuffer(
//input                  i_clk,        // System clock: triggers all logic updates
//input                  i_rst,        // Reset signal: clears pointers to start over
//input   [7:0]          i_data,       // 8-bit input: current pixel/data byte coming in
//input                  i_data_valid, // High when valid data is present on i_data
//output  [23:0]         o_data,       // 24-bit output: outputs 3 pixels (3x8 bits) at once
//input                  i_rd_data     // High when the next stage is ready to read/shift
//);

//// Internal storage: 512 memory slots, each 8 bits wide
//reg [7:0] line [511:0]; 

//// Pointers: 9 bits wide to cover addresses 0 to 511 (2^9 = 512)
//reg [8:0] wrPntr; // Tracks where to write the next incoming pixel
//reg [8:0] rdPntr; // Tracks the starting point of the 3-pixel window for reading

//// --- WRITE LOGIC ---
//always @(posedge i_clk) // Every time the clock rises...
//begin
//    if(i_data_valid)    // If there is valid data arriving...
//        line[wrPntr] <= i_data; // Store the input data into the current memory slot
//end

//always @(posedge i_clk)
//begin
//    if(i_rst)           // If reset is active...
//        wrPntr <= 'd0;  // Send write pointer back to the start (address 0)
//    else if(i_data_valid) // If we just wrote data...
//        wrPntr <= wrPntr+1; // Move to the next memory slot (rolls over at 511)
//end

//// --- READ LOGIC (Combinational) ---
//// This combines 3 consecutive bytes from memory into one 24-bit bus.
//// It effectively looks at a "window" of 3 pixels: [Current, Next, Next+1]
//assign o_data = {line[rdPntr], line[rdPntr+1], line[rdPntr+2]};

//// --- READ POINTER LOGIC ---
//always @(posedge i_clk)
//begin
//    if(i_rst)           // If reset is active...
//        rdPntr <= 'd0;  // Send read pointer back to the start
//    else if(i_rd_data)  // If the "read" signal is high...
//        rdPntr <= rdPntr + 'd1; // Shift the reading window forward by one
//end

//endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2020 07:25:49 PM
// Design Name: 
// Module Name: lineBuffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//11111
module lineBuffer(
input   i_clk,
input   i_rst,
input [7:0] i_data,
input   i_data_valid,
output [23:0] o_data,
input i_rd_data
);

reg [7:0] line [511:0]; //line buffer
reg [8:0] wrPntr;
reg [8:0] rdPntr;

always @(posedge i_clk)
begin
    if(i_data_valid)
        line[wrPntr] <= i_data;
end

always @(posedge i_clk)
begin
    if(i_rst)
        wrPntr <= 'd0;
    else if(i_data_valid)
        wrPntr <= wrPntr + 'd1;
end

assign o_data = {line[rdPntr],line[rdPntr+1],line[rdPntr+2]};

always @(posedge i_clk)
begin
    if(i_rst)
        rdPntr <= 'd0;
    else if(i_rd_data)
        rdPntr <= rdPntr + 'd1;
end


endmodule
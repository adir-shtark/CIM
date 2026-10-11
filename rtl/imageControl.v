//`timescale 1ns / 1ps

//module imageControl(
//    input             i_clk,
//    input             i_rst,
//    input      [7:0]  i_pixel_data,       // Incoming 8-bit pixel stream
//    input             i_pixel_data_valid, // High when valid pixel data is present
//    output reg [71:0] o_pixel_data,       // Concatenated 3-line output (3x24-bit)
//    output            o_pixel_data_valid, // Signal to downstream processing
//    output reg        o_intr              // Interrupt/Done signal for one line read
//);

////processes 1-2 = in charge on reading and writing to the whole image, 
////processes 4-5 = writing control. 6-9 = reading control. 
////very similar, because every time you read/write 512 times, you switch to the next line buffer.

//// Internal Registers and Wires
//reg  [8:0]  pixelCounter;                       // Tracks horizontal position (0-511).
//                                                // in processes 3 4, it make sure every 512 pixels it will write from the camer to the next line buffer!!
//reg  [1:0]  currentWrLineBuffer;                // Points to the buffer currently being written to
//reg  [3:0]  lineBuffDataValid;                  // Write-enable demux for the 4 buffers.
//                                                // i_pixel_data is connected to all 4 line buffers, 
//                                                // but we set the valid input only to one line buffer at a time, in processes 4 5
//reg  [3:0]  lineBuffRdData;                     // Read-enable demux for the 4 buffers
//reg  [1:0]  currentRdLineBuffer;                // Tracks which set of 3 buffers to read from.
//                                                // after reading 512 pixels, it will switch to the next line buffer, in processes 7 8 9
//wire [23:0] lb0data, lb1data, lb2data, lb3data; // Data outputs from individual line buffers
//reg  [8:0]  rdCounter;                          // Tracks read progress (0-511). every 
//reg         rd_line_buffer;                     // Internal read-enable flag
//reg  [11:0] totalPixelCounter;                  // Tracks global occupancy of buffers
//reg         rdState;                            // FSM State

//localparam IDLE = 'b0, RD_BUFFER = 'b1;

//assign o_pixel_data_valid = rd_line_buffer;

//// 1. Manage Total Pixel Count: Increments on write, decrements on read
//always @(posedge i_clk) begin
//    if(i_rst)
//        totalPixelCounter <= 0;
//    else begin
//        if(i_pixel_data_valid & !rd_line_buffer)
//            totalPixelCounter <= totalPixelCounter + 1;
//        else if(!i_pixel_data_valid & rd_line_buffer)
//            totalPixelCounter <= totalPixelCounter - 1;
//    end
//end

//// 2. FSM: Controls when to start reading from buffers
//always @(posedge i_clk) begin
//    if(i_rst) 
//    begin
//        rdState <= IDLE;
//        rd_line_buffer <= 1'b0;
//        o_intr <= 1'b0;
//    end else
//     begin
//        case(rdState)
//            IDLE: begin
//                o_intr <= 1'b0;
//                // Start reading once 3 full lines (512 * 3 = 1536) are stored
//                if(totalPixelCounter >= 1536) begin
//                    rd_line_buffer <= 1'b1;
//                    rdState <= RD_BUFFER;
//                end
//            end
//            RD_BUFFER: begin
//                // Stop reading after one full line (512 pixels) is processed
//                if(rdCounter == 511) begin
//                    rdState <= IDLE;
//                    rd_line_buffer <= 1'b0;
//                    o_intr <= 1'b1; // Trigger interrupt indicating line completion
//                end
//            end
//        endcase
//    end
//end

//// 3. Pixel Counter: Wraps every 512 pixels
//always @(posedge i_clk) begin
//    if(i_rst) pixelCounter <= 0;
//    else if(i_pixel_data_valid) pixelCounter <= pixelCounter + 1;
//end

//// 4. Write Pointer: Switches to the next buffer after every 512 pixels
//always @(posedge i_clk) begin
//    if(i_rst) currentWrLineBuffer <= 0;
//    else if(pixelCounter == 511 & i_pixel_data_valid)
//        currentWrLineBuffer <= currentWrLineBuffer + 1; //every time it full and adding one,it goes back to 0!!!
//                                                        // so I am writing to the buffer 0,1,2,3,0,1,2,3...
//end

//// 5. Demux: Only send 'valid' signal to the buffer currently being written, wich is set by currentWrLineBuffer from last process
//always @(*) begin
//    lineBuffDataValid = 4'h0;
//    lineBuffDataValid[currentWrLineBuffer] = i_pixel_data_valid; 
//end

//// 6. Read Counter and Pointer Logic
//always @(posedge i_clk) begin
//    if(i_rst) rdCounter <= 0;
//    else if(rd_line_buffer) rdCounter <= rdCounter + 1; //when rdCounter is full, addint 1 will restart it to 0!!!!!!
//end



//// 7. if the read_counter is full, switch to the next line buffer!!!!!!
//always @(posedge i_clk) begin
//    if(i_rst) currentRdLineBuffer <= 0;
//    else if(rdCounter == 511 & rd_line_buffer)
//        currentRdLineBuffer <= currentRdLineBuffer + 1;
//end

//// 8. Output Mux: Selects which 3 buffers form the sliding window
//// This handles the "rotating" nature of the line buffers
//always @(*) begin
//    case(currentRdLineBuffer)
//        0: o_pixel_data = {lb2data, lb1data, lb0data}; //all 9 pixels, 3 from each row!!!!!!
//        1: o_pixel_data = {lb3data, lb2data, lb1data};
//        2: o_pixel_data = {lb0data, lb3data, lb2data};
//        3: o_pixel_data = {lb1data, lb0data, lb3data};
//    endcase
//end


//// 9. Read Enable Mux: Activates read for 3 buffers, keeps 1 idle (for writing)
//always @(*) begin
//    case(currentRdLineBuffer)
//        0: lineBuffRdData = 4'b0111; 
//        1: lineBuffRdData = 4'b1110;
//        2: lineBuffRdData = 4'b1101;
//        3: lineBuffRdData = 4'b1011;
//    endcase
//end




////------------------------------------------------------------------------------------------

//// Instantiate 4 physical line buffers
//lineBuffer lB0(
//    .i_clk(i_clk), 
//    .i_rst(i_rst), 
//    .i_data(i_pixel_data), 
//    .i_data_valid(lineBuffDataValid[0]), 
//    .o_data(lb0data), 
//    .i_rd_data(lineBuffRdData[0])
//    );
//lineBuffer lB1(
//    .i_clk(i_clk), 
//    .i_rst(i_rst), 
//    .i_data(i_pixel_data), 
//    .i_data_valid(lineBuffDataValid[1]), 
//    .o_data(lb1data), 
//    .i_rd_data(lineBuffRdData[1])
//    );
//lineBuffer lB2(
//    .i_clk(i_clk), 
//    .i_rst(i_rst), 
//    .i_data(i_pixel_data), 
//    .i_data_valid(lineBuffDataValid[2]), 
//    .o_data(lb2data), 
//    .i_rd_data(lineBuffRdData[2])
//    );
//lineBuffer lB3(
//    .i_clk(i_clk), 
//    .i_rst(i_rst), 
//    .i_data(i_pixel_data), 
//    .i_data_valid(lineBuffDataValid[3]), 
//    .o_data(lb3data), 
//    .i_rd_data(lineBuffRdData[3])
//    );

//endmodule



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2020 10:53:27 AM
// Design Name: 
// Module Name: imageControl
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

module imageControl(
input                    i_clk,
input                    i_rst,
input [7:0]              i_pixel_data,
input                    i_pixel_data_valid,
output reg [71:0]        o_pixel_data,
output                   o_pixel_data_valid,
output reg               o_intr
);

reg [8:0] pixelCounter;
reg [1:0] currentWrLineBuffer;
reg [3:0] lineBuffDataValid;
reg [3:0] lineBuffRdData;
reg [1:0] currentRdLineBuffer;
wire [23:0] lb0data;
wire [23:0] lb1data;
wire [23:0] lb2data;
wire [23:0] lb3data;
reg [8:0] rdCounter;
reg rd_line_buffer;
reg [11:0] totalPixelCounter;
reg rdState;

localparam IDLE = 'b0,
           RD_BUFFER = 'b1;

assign o_pixel_data_valid = rd_line_buffer;

always @(posedge i_clk)
begin
    if(i_rst)
        totalPixelCounter <= 0;
    else
    begin
        if(i_pixel_data_valid & !rd_line_buffer)
            totalPixelCounter <= totalPixelCounter + 1;
        else if(!i_pixel_data_valid & rd_line_buffer)
            totalPixelCounter <= totalPixelCounter - 1;
    end
end

always @(posedge i_clk)
begin
    if(i_rst)
    begin
        rdState <= IDLE;
        rd_line_buffer <= 1'b0;
        o_intr <= 1'b0;
    end
    else
    begin
        case(rdState)
            IDLE:begin
                o_intr <= 1'b0;
                if(totalPixelCounter >= 1536)
                begin
                    rd_line_buffer <= 1'b1;
                    rdState <= RD_BUFFER;
                end
            end
            RD_BUFFER:begin
                if(rdCounter == 511)
                begin
                    rdState <= IDLE;
                    rd_line_buffer <= 1'b0;
                    o_intr <= 1'b1;
                end
            end
        endcase
    end
end
    
always @(posedge i_clk)
begin
    if(i_rst)
        pixelCounter <= 0;
    else 
    begin
        if(i_pixel_data_valid)
            pixelCounter <= pixelCounter + 1;
    end
end


always @(posedge i_clk)
begin
    if(i_rst)
        currentWrLineBuffer <= 0;
    else
    begin
        if(pixelCounter == 511 & i_pixel_data_valid)
            currentWrLineBuffer <= currentWrLineBuffer+1;
    end
end


always @(*)
begin
    lineBuffDataValid = 4'h0;
    lineBuffDataValid[currentWrLineBuffer] = i_pixel_data_valid;
end

always @(posedge i_clk)
begin
    if(i_rst)
        rdCounter <= 0;
    else 
    begin
        if(rd_line_buffer)
            rdCounter <= rdCounter + 1;
    end
end

always @(posedge i_clk)
begin
    if(i_rst)
    begin
        currentRdLineBuffer <= 0;
    end
    else
    begin
        if(rdCounter == 511 & rd_line_buffer)
            currentRdLineBuffer <= currentRdLineBuffer + 1;
    end
end


always @(*)
begin
    case(currentRdLineBuffer)
        0:begin
            o_pixel_data = {lb2data,lb1data,lb0data};
        end
        1:begin
            o_pixel_data = {lb3data,lb2data,lb1data};
        end
        2:begin
            o_pixel_data = {lb0data,lb3data,lb2data};
        end
        3:begin
            o_pixel_data = {lb1data,lb0data,lb3data};
        end
    endcase
end

always @(*)
begin
    case(currentRdLineBuffer)
        0:begin
            lineBuffRdData[0] = rd_line_buffer;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = 1'b0;
        end
       1:begin
            lineBuffRdData[0] = 1'b0;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = rd_line_buffer;
        end
       2:begin
             lineBuffRdData[0] = rd_line_buffer;
             lineBuffRdData[1] = 1'b0;
             lineBuffRdData[2] = rd_line_buffer;
             lineBuffRdData[3] = rd_line_buffer;
       end  
      3:begin
             lineBuffRdData[0] = rd_line_buffer;
             lineBuffRdData[1] = rd_line_buffer;
             lineBuffRdData[2] = 1'b0;
             lineBuffRdData[3] = rd_line_buffer;
       end        
    endcase
end
    
lineBuffer lB0(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(i_pixel_data),
    .i_data_valid(lineBuffDataValid[0]),
    .o_data(lb0data),
    .i_rd_data(lineBuffRdData[0])
 ); 
 
 lineBuffer lB1(
     .i_clk(i_clk),
     .i_rst(i_rst),
     .i_data(i_pixel_data),
     .i_data_valid(lineBuffDataValid[1]),
     .o_data(lb1data),
     .i_rd_data(lineBuffRdData[1])
  ); 
  
  lineBuffer lB2(
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_data(i_pixel_data),
      .i_data_valid(lineBuffDataValid[2]),
      .o_data(lb2data),
      .i_rd_data(lineBuffRdData[2])
   ); 
   
   lineBuffer lB3(
       .i_clk(i_clk),
       .i_rst(i_rst),
       .i_data(i_pixel_data),
       .i_data_valid(lineBuffDataValid[3]),
       .o_data(lb3data),
       .i_rd_data(lineBuffRdData[3])
    );    
    
endmodule
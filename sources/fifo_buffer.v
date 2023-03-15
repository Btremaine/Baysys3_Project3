`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03//07/23 08:25:00 AM
// Design Name: 
// Module Name:  fifo_buffer.v
// source:       https://esrd2014.blogspot.com/p/first-in-first-out-buffer.html
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  fifo buffer with parameters to set bit width and word depth
//               data_in[] : data input word
//					  clk:        system clock       
//					  EN:         Enable, fifo is in hold mode when EN is false.
//					  rd:         read fifo when rd is true
//					  wr          write fifo when wr is true
//					  rst_n       reset, active low. 
//               data_o[]:   data output word   
//               EMPTY       set high when fifo is empty 
//               FULL        set high when fifo is full					    
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// This file implements a fifo buffer. First location writter is index 0,
//
// 
///////////////////////////////////////////////////////////////////////////////////
module fifo_buffer
  #(parameter DEPTH = 8, parameter WIDTH = 8)
  (
   input                  rst_n,
   input [WIDTH-1:0]      data_in,
   input                  sys_clk,
   input                  EN,
   input                  rd,
   input                  wr,
   output reg [WIDTH-1:0] data_o,
   output                 EMPTY,
   output                 FULL );

   reg [2:0]  Count = 0;  
   reg [7:0]  FIFO [0:7]; 
	
   reg [2:0]  readCounter;
	reg [2:0]  writeCounter; 
   assign EMPTY = (Count == 0)? 1'b1:1'b0; 
   assign FULL = (Count == DEPTH)? 1'b1:1'b0; 
 
   always @ (posedge sys_clk) 
   begin 
   if (EN==0); 
   else begin 
    if (!rst_n) begin 
     readCounter  <= 0; 
     writeCounter <= 0; 
    end 
   else if (rd == 1'b1 && Count!=0) begin 
    data_o  <= FIFO[readCounter]; 
    readCounter <= readCounter + 1'b1; 
   end 
   else if (wr==1'b1 && Count< DEPTH) begin
    FIFO[writeCounter]  <= data_in; 
    writeCounter  <= writeCounter + 1'b1; 
   end 
   else; 
   end 

   if (writeCounter== DEPTH) 
     writeCounter<=0; 
   else if (readCounter== DEPTH) 
    readCounter<=0; 
   else;
     if (readCounter > writeCounter) begin 
       Count=readCounter-writeCounter; 
     end 
     else if (writeCounter > readCounter) 
       Count <= writeCounter-readCounter; 
     else;
    end 

endmodule


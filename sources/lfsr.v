//-----------------------------------------------------------------------------
//  Module   : lfsr.v
//  Parent   : lfst_top.v
//  Children : none
//  Description:
//     This implements a 13-bit maximal LFSR (Fibonacci)
//     p = x^13 + x^12 + x^11  + x^8 + 1
//  Parameters:
//     None
//-----------------------------------------------------------------------------
//`include "timescale.v"
module lfsr #(parameter NUM_BITS= 16)
(
     input clk,                    // system clock
     input rst_n,
     input pulse,                   // input to advance lfsr
     output [NUM_BITS-1:0] word );  // output of lfsr register
     
     // registers used
     reg [NUM_BITS-1:0] poly;
     reg Q1;
     reg Q2;
     reg r_XNOR;
     
     //parameters
     localparam SEED = 16'h5EED;  // can't be 0 !!
     
     always @(posedge clk) begin
        if( rst_n == 0 ) begin
           Q1 <= 0;
           Q2 <= 0;
        end
        else begin
           Q1 <= pulse;
           Q2 <= Q1;
        end
    end   
     
     always@( posedge clk ) begin  // pulse needs to be buffered, DRC warning in synthesis
         if( rst_n == 0 )
            poly <= SEED;
         else if (Q1 && !Q2) begin
            poly[NUM_BITS-1:0] <= {poly[NUM_BITS-2:0], r_XNOR};
         end // if   
     end // always
     
     always@ (*) begin
         r_XNOR <= poly[15] ^ poly[14] ^ poly[12] ^ poly[3];   
     end //always
     
     assign word = poly[NUM_BITS-1:0];
     
endmodule

//-----------------------------------------------------------------------------
//  Module   : reset_gen.v
//  Parent   : lfsr_top.v
//  Children : none
//  Description:
//     This module generates a refresh reset (active low) synced to clk
//     and an intermediate system clk.
//
//     "inp" is active high reset and must be preset for DELAY clk counts to
//      assert reset, then reset is high for DELAY counts.
//  Parameters:
//     None
//
//`include "timescale.v"
//-----------------------------------------------------------------------
module  reset_gen
	(
	input clk,              // basys3 5Mhz
	input inp,              // source of reset, active high btn
	output reg rst_n        // reset output, active low
	);
//// ---------------- internal constants --------------
    
    localparam  WIDTH =   16;
	 localparam [WIDTH-1:0] DELAY = 5000;   // clk cycles
       
////---------------- internal variables ---------------
    reg [WIDTH-1:0] count = 15'b0; 
	 wire reset;
    
    always@(posedge clk) begin
       if(inp == 0) begin
          count <= 0;
       end
       else begin
         if( count > DELAY - 1'b1)
            count <= DELAY;
         else count <= count + 1'b1;
       end
    end // always
	 
	 assign reset = count == DELAY  ? 1'b0  : 1'b1;
	 
	 always@(posedge clk) begin
	    rst_n <= ~reset;
    end
    

endmodule
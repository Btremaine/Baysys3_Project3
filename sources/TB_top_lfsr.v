//`include "..\includes\timescale.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2023 10:23:24 AM
// Design Name: 
// Module Name: TB_top_lfsr
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
`timescale 1ns/1ps

module  TB_top_lfsr;

// testbemch requirements
// inputs
  reg CLK50MHZ;
  reg reset;
 //======================

 // internal wires and reg
  // wire sys_clk;
 
  top_lfsr top_lfsr_1(
    // inputs
    .CLK50MHZ    (CLK50MHZ),
    .btnU        (reset),      // active high reset
    .cath_out    (),
    .enable      (),
    .led         (),
	 .RsTx        () ); 
  
    
always begin
 #10 CLK50MHZ = !CLK50MHZ;   // ~50Mhz
end  

    
initial begin                                 
   CLK50MHZ = 0;
   reset = 0;
end


initial begin
// start bench test, run for 25ms 
#20 CLK50MHZ = 0;
#50_000    reset = 1;
#50_000    reset = 0;
#50_000    reset = 1;
#75_000    reset = 0;


//#4_000_000 $finish;
#1_400_000_000 $finish ;
end

endmodule

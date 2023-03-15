//-----------------------------------------------------------------------------
//  Project  : Quartus
//  Module   : design_block.v

//  Parent   : top_lfsr

//  Children : none
//  Description:

//     This module implements the block design used in the Vivado Basys3 projet
//
//  Parameters:
//     None
//
//  Notes:

//`include "timescale.v"
//------------------------------------------------------------------------------
module design_block
(
   input  clk_5MHz,        //clock signal
   input  rst_n,           //input button
   output [3:0] enable,    //anode enable
   output [6:0] cath_out,  //cathode
   output update,          //update_1Hz
   output [15:0] word );

  wire update_1Hz;
  wire refresh_rate;
	
  // instantiate modules
  div_by_N #(.N(32767), .Nb(16)) div_by_N_1 (
    .rst_n       (rst_n),
    .clk_in      (clk_5MHz), 
    .Q_out       (refresh_rate) );  // LCD refresh rate
    
  div_by_N  #(.N(100000), .Nb(17)) div_by_N_2 (   // normally 5000000, debug with 500000
    .rst_n       (rst_n),
    .clk_in      (clk_5MHz), 
    .Q_out       (update_1Hz) );    // LFSR update rate
	 
   // linear feedback shift register (pseudorandom generator)
  lfsr #(.NUM_BITS(16)) lfsr_1 (
    .rst_n       (rst_n),
    .clk         (clk_5MHz),
    .pulse       (update_1Hz ), 
    .word        (word) );
  
  // 7-segment display 
  Seven_Seg_Display_Control Seven_Seg_Display_Control_1 (
    .clk1        (clk_5MHz),
    .rst_n       (~rst_n),
    .refresh     (refresh_rate),
    .word        (word),
    //
    .cath_out    (cath_out), // cathode signals
    .anode       (enable) ); // anode enable
	
  assign update = update_1Hz;	
 

endmodule
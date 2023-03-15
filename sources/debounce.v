//-----------------------------------------------------------------------------
//  Project  : Basys 3 Dev board
//  Module   : debounce.v

//  Parent   : top_lfsr

//  Children : none
//  Description:

//     This module debounces an external button on the Basys 3 Dev Board
//
//  Parameters:
//     None
//
//  Notes:

//`include "timescale.v"
//-----------------------------------------------------------------------
module debounce #(parameter threshold = 2000 ) //
(
   input clk,          //clock signal
   input btn,          //input button
   output reg outp     //debounced signal
);
    
localparam Nb= 11;	 
reg button_ff1  = 0; //button flip-flop for synchronization. Initialize it to 0
reg button_ff2  = 0; //button flip-flop for synchronization. Initialize it to 0
reg [Nb:0]count = 0; //20 bits count for increment & decrement when button is pressed or released. Initialize it to 0 

// First use two flip-flops to synchronize the button signal the "clk" clock domain
always @(posedge clk)begin
  button_ff1 <= btn;
  button_ff2 <= button_ff1;
end

// When the push-button is pushed or released, we increment or decrement the counter
// The counter has to reach threshold before we decide that the push-button state has changed
always @(posedge clk) begin 
  if (button_ff2) //if button_ff2 is 1
  begin
    if (~&count)//if it isn't at the count limit. Make sure won't count up at the limit. First AND all count and then not the AND
        count <= count + 1'b1; // when btn pressed, count up
  end else begin
    if (|count)//if count has at least 1 in it. Make sure no subtraction when count is 0 
        count <= count - 1'b1; //when btn relesed, count down
 end
 if (count > threshold)//if the count is greater the threshold 
    outp <= 1; //debounced signal is 1
 else
    outp <= 0; //debounced signal is 0
end

endmodule
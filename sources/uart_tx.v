`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2023 08:25:00 AM
// Design Name: Brian Tremaine
// Module Name: uart_3alw_tx
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
// This file implements a UART Transmitter using 3-always blocks.  
// This transmitter is able to transmit 8 bits of serial data, one start bit, 
// one stop bit, and no parity bit. When transmit is complete Tx_done_o will be
// driven high for one clock cycle.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of clk_uart_i)/(Frequency of UART)
// Example: 5 MHz Clock, 9600 baud UART
// (5000000)/(9600) = 521
///////////////////////////////////////////////////////////////////////////////////
module uart_tx 
  #(parameter CLKS_PER_BIT = 521)
  (
   input       rst_n,
   input       clk_uart_i,
   input       tx_dv_i,
   input [7:0] tx_byte_i,         // (ascii) byte to be serialized 
   output reg  tx_active_o,       // active status bit
   output reg  tx_serial_o,       // serial data out
   output reg  tx_done_o  );      // done status bit
 
  // define state machine names (1-hot)
  localparam IDLE         = 4'b0000;
  localparam TX_START_BIT = 4'b0010;
  localparam TX_DATA_BITS = 4'b0100;
  localparam TX_STOP_BIT  = 4'b1000;
  
  reg [3:0] sm_main_r;
  reg [$clog2(CLKS_PER_BIT):0] Clock_Count_r;
  reg [3:0] Bit_Index_r;
  reg [7:0] TX_Data_r;

  // Implement uart TX state machine
  // using a 1-always method including a baudbit counter
  // synchronous update of current state to next state within @always.
  //   input:  rst_n (synchronous)  resets to IDLE state
  //   input:  tx_dv_i
  //   input:  tx_byte_i
  //   output: tx_done_o
  //   output: tx_serial_o
  //   output: tx_active_o
  
  always @(*)  TX_Data_r = tx_byte_i;
  
  
  always @(posedge clk_uart_i)
  if ( rst_n == 0 )
    begin
      sm_main_r <= IDLE;
    end else begin 
    begin
      case (sm_main_r)
      IDLE :
        begin
          tx_done_o <= 1'b0;
          tx_serial_o   <= 1'b1;         // Drive Line High for Idle			 
          Bit_Index_r   <= 4'b0000;
          Clock_Count_r <= 0;
          if (tx_dv_i == 1'b1)
          begin
            tx_active_o <= 1'b1;
            //TX_Data_r   <= tx_byte_i;
            sm_main_r <= TX_START_BIT;
            Clock_Count_r <= 0;
          end
          else
            sm_main_r <= IDLE;
        end // case: IDLE  
         
      TX_START_BIT :  // Send out Start Bit. Start bit = 0
        begin
           tx_serial_o <= 1'b0;
           // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
           if (Clock_Count_r < CLKS_PER_BIT - 1'b1) 
              Clock_Count_r <= Clock_Count_r + 1'b1;
		     else begin
              sm_main_r <= TX_DATA_BITS;
			     Clock_Count_r <= 0;
		     end		 
        end // case: TX_START_BIT 
                
      TX_DATA_BITS :
        begin
          tx_serial_o <= TX_Data_r[Bit_Index_r];          
          if (Clock_Count_r < CLKS_PER_BIT - 1'b1)
          begin
            Clock_Count_r <= Clock_Count_r + 1'b1;
            sm_main_r <= TX_DATA_BITS;
          end
          else
          begin
            Clock_Count_r <= 0;          
            // Check if we have sent out all bits
            if (Bit_Index_r < 4'b0111)
            begin
              Bit_Index_r <= Bit_Index_r + 1'b1;
              sm_main_r   <= TX_DATA_BITS;
            end
            else
            begin
              sm_main_r   <= TX_STOP_BIT;
            end
          end 
        end // case: TX_DATA_BITS     
                    
      TX_STOP_BIT :   // Send out Stop bit.  Stop bit = 1
        begin
           tx_serial_o <= 1'b1;          
           // Wait for baudbit period for Stop bit to finish
           if (Clock_Count_r < CLKS_PER_BIT - 1'b1) 
              Clock_Count_r <= Clock_Count_r + 1'b1;
		     else begin
              sm_main_r <= IDLE;
			     Clock_Count_r <= 0;	     
              tx_done_o     <= 1'b1;
              tx_active_o   <= 1'b0;
           end 
        end // case: TX_STOP_BIT          
      default :
        sm_main_r <= IDLE;     
    endcase
    end // else: !if(~rst_n)
  end // always @ (posedge clock_uart_i)

endmodule


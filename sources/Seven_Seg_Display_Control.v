//////////////////////////////////////////////////////////////////////////////////
//  Module   : Seven_Seg_Display_Control.v
//  Parent   : lfsr.v
//  Children : none
//  Description:
//     This module updates the 7-segment LED display assuming HEX digits
//     The DP is not used.
//  Parameters:
//     None
///////////////////////////////////////////////////////////////////////////////////
//`include "timescale.v"

/////////////////////////////Basys 3 FPGA   ///////////////////////////////////////

module Seven_Seg_Display_Control(
    input clk1,                 // sys_clk
    input rst_n,                // reset active low
    input refresh,              // clock at visual refresh rate, nominally 120Hz 
    input [15:0] word,          // lfsr register to be displayed
    output reg [6:0] cath_out,  // cathode signals
    output reg [3:0] anode      // anode enables
    );
	
	// registers used	
	 wire sys_clk;
    reg [3:0] LED_HEX;
    reg [1:0] digit_counter; 
                 // count         0   ->  1   ->  2  ->  3
                 // activates    LED1    LED2   LED3   LED4
                 // and repeat   
    reg Q1;
    reg Q2; 
            
    // wires
	 wire reset;
    
    always @(posedge sys_clk or posedge reset) begin
        if( reset==1) begin
           Q1 <= 0;
           Q2 <= 0;
        end
        else begin
           Q1 <= refresh;
           Q2 <= Q1;
        end
    end   
             
    always @(posedge sys_clk or posedge reset) begin
        if (reset==1)          
            digit_counter <= 0;
        else begin
            if (Q1 && !Q2) begin
               if ( digit_counter < 3) begin
                     digit_counter <= digit_counter + 1'b1;
               end else
                  digit_counter <= 0;
             end
        end
    end	
	
	// anode activating signals for 4 LEDs, digit period of 2.6ms
    // decoder to generate anode signals from digit nibble
    always @(*)
    begin
        case(digit_counter)
        2'b00: begin
            anode = 4'b0111; 
            // activate LED1 and Deactivate LED2, LED3, LED4
            LED_HEX = word[15:12];
            // the first digit of the 16-bit number
              end
        2'b01: begin  
            anode = 4'b1011; 
            // activate LED2 and Deactivate LED1, LED3, LED4
            LED_HEX = word[11:8];
            // the second digit of the 16-bit number
              end
        2'b10: begin
            anode = 4'b1101; 
            // activate LED3 and Deactivate LED2, LED1, LED4
            LED_HEX = word[7:4];
            // the third digit of the 16-bit number
                end
        2'b11: begin
            anode = 4'b1110; 
            // activate LED4 and Deactivate LED2, LED3, LED1
            LED_HEX = word[3:0];
            // the fourth digit of the 16-bit number    
               end
        endcase
    end
	
    // Cathode patterns of the 7-segment LED display 
    always @(*)
    begin
        case(LED_HEX) // ---- updated mapping table for hex
        4'b0000: cath_out = 7'b0000001; // "0"     
        4'b0001: cath_out = 7'b1001111; // "1" 
        4'b0010: cath_out = 7'b0010010; // "2" 
        4'b0011: cath_out = 7'b0000110; // "3" 
        4'b0100: cath_out = 7'b1001100; // "4" 
        4'b0101: cath_out = 7'b0100100; // "5" 
        4'b0110: cath_out = 7'b0100000; // "6" 
        4'b0111: cath_out = 7'b0001111; // "7" 
        4'b1000: cath_out = 7'b0000000; // "8"     
        4'b1001: cath_out = 7'b0000100; // "9" 
        4'b1010: cath_out = 7'b0001000; // "A" 
        4'b1011: cath_out = 7'b1100000; // "b" 
        4'b1100: cath_out = 7'b0110001; // "C" 
        4'b1101: cath_out = 7'b1000010; // "d" 
        4'b1110: cath_out = 7'b0110000; // "E"     
        4'b1111: cath_out = 7'b0111000; // "F"
        default: cath_out = 7'b0000001; // "0"
        endcase
    end
    
    assign sys_clk = clk1;
	 assign reset = !rst_n;
    
 endmodule
 
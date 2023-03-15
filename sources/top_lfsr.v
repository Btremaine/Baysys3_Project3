//////////////////////////////////////////////////////////////////////////////////
// Company:     Tremaine Consulting Group
// Engineer:    Brian Tremaine
// 
// Create Date: 02/18/2023 08:25:35 AM
// Design Name: 
// Module Name: top_lfsr
// Project Name:  
// Target Devices: DEO NANO board, Cyclone IV 
// Tool Versions:  Quartus Prime Lite 20.1 (incl ModelSim)
// Description:    top module for Cyclone IV project (learning Quartus)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//`include "timescale.v"

// list external pins by name in XDC file
module top_lfsr (
   input  CLK50MHZ,        // board clock
   input  btnU,            // manual reset
   output [6:0] cath_out,  // cathode active low
   output [3:0] enable,    // anode active active high  clk1
   output reg [2:0] led,
   output RsTx
  );
  
  // define data transfer state machine names
 
  localparam CLKS_PER_BIT  = 521;
  localparam FIFO_IDLE     = 5'b00000; // idle state
  localparam FIFO_DIGIT_0  = 5'b00001; // digit 1 to fifo
  localparam FIFO_DIGIT_1  = 5'b00010; // digit 2 to fifo
  localparam FIFO_DIGIT_2  = 5'b00100; // digit 3 to fifo
  localparam FIFO_DIGIT_3  = 5'b01000; // digit 4 to fifo
  localparam FIFO_NEW_LINE = 5'b10000; // send new-line
  localparam LF            = 8'h0a;    // ASCII LF
  localparam DEPTH_FIFO    = 4'd8;     // fifo word depth
  localparam WIDTH_FIFO    = 4'd8;     // fifo bit width
  
  localparam SEND_IDLE     = 5'b00000; // idle state
  localparam SEND_DIGIT_0  = 5'b00001; // digit 1 to uart
  localparam SEND_DIGIT_1  = 5'b00010; // digit 2 to uart
  localparam SEND_DIGIT_2  = 5'b00100; // digit 3 to uart
  localparam SEND_DIGIT_3  = 5'b01000; // digit 4 to uart
  localparam SEND_NEW_LINE = 5'b10000; // new-line to uart 
  
  reg [5:0] sm_digit_r;  // state of fifo, 6 state FSM
  reg [5:0] sm_send_r;   // state of transmission to uart, 6 state FSM
  
  // internal wires and reg
  wire update_1Hz;
  wire sys_clk;
  wire locked;
  wire rst_n;
  wire clk_5MHz;
  wire pulse;
  wire tx_active_o;
  wire tx_serial_o;
  wire tx_done;
  wire clk_50MHz;
  wire [15:0] hex_word;
  reg [3:0] hex_nibble = 4'b0000;
  wire [WIDTH_FIFO-1:0] data_out;
  wire empty;
  wire full;
  reg  tx_dv_dly_1;
  
  reg SEND_start;
  
  reg  rd;
  reg  wr;
  reg  EN;
  reg  word_change;
  reg  [15:0] old_hex_word;
  reg  [7:0]  ascii_byte;
  reg  Led;
  reg  btnU_1;
  reg  btnU_2;
  reg  btnU_3;
  reg  tx_dv;
  reg  [7:0] data_in;
  
  // instaniate modified BD
  design_block design_block_1
  (
	 .clk_5MHz  (sys_clk),
	 .rst_n     (rst_n),
	 .enable    (enable),
    .cath_out  (cath_out),
    .update    (update_1Hz),
    .word      (hex_word) );    // hex_word updated rising edge of update_1Hz
  
  // reset generator 
  reset_gen reset_gen_1
  (
	.clk       (sys_clk),        // basys3 5Mhz
	.inp        (pulse),         // source of reset, active high debounced btn
	.rst_n      (rst_n) );       // reset output, active low
	 
  // debounce button logic
  debounce debounce_1 
  (
   .clk        (sys_clk),       // 5Mhz
   .btn        (~btnU),         // reset active high
   .outp       (pulse) );       // debounced output
	

  // system clock IP
  clk_wiz clk_wiz_1 
  (
	.areset      (1'b0),         // do not reset, FIX IP, DEO Nano 50MHz
	.inclk0      (clk_50MHz),   
	.c0          (clk_5MHz),
	.locked      (locked) ); 
	
	 
   // uart transmitter
  uart_tx  #(.CLKS_PER_BIT(521) ) uart_tx_1 
  (  
   .rst_n        (rst_n),
   .clk_uart_i   (sys_clk),
   .tx_dv_i      (tx_dv_dly_1), // data valid strobe
   .tx_byte_i    (data_out),    // ASCII byte to tx
   .tx_active_o  (tx_active_o), // active status
   .tx_serial_o  (tx_serial_o), // tx serial data
   .tx_done_o    (tx_done) );   // done status
	
	// fifo buffer
	fifo_buffer #(.DEPTH(DEPTH_FIFO), .WIDTH(WIDTH_FIFO) ) fifo_buffer_1 
	(
	.rst_n        (rst_n),
	.data_in      (data_in),     // input word
	.sys_clk      (sys_clk),
	.EN           (EN),          // enable fifo
	.rd           (rd),          // rd strobe
	.wr           (wr),          // wr strobe
	.data_o       (data_out),    // output word
	.EMPTY        (empty),       // EMPTY status
	.FULL         (full) );      // FULL status
		

    // hex to ascii conversion for uart tx_data
    always @(*)
    begin 
	     //hex_nibble =     // hex_word[
		  
        case(hex_nibble) // ---- updated mapping table for hex
        4'b0000: ascii_byte = 8'h30; // "0"     
        4'b0001: ascii_byte = 8'h31; // "1" 
        4'b0010: ascii_byte = 8'h32; // "2" 
        4'b0011: ascii_byte = 8'h33; // "3" 
        4'b0100: ascii_byte = 8'h34; // "4" 
        4'b0101: ascii_byte = 8'h35; // "5" 
        4'b0110: ascii_byte = 8'h36; // "6" 
        4'b0111: ascii_byte = 8'h37; // "7" 
        4'b1000: ascii_byte = 8'h38; // "8"     
        4'b1001: ascii_byte = 8'h39; // "9" 
        4'b1010: ascii_byte = 8'h61; // "a" 
        4'b1011: ascii_byte = 8'h62; // "b" 
        4'b1100: ascii_byte = 8'h63; // "c" 
        4'b1101: ascii_byte = 8'h64; // "d" 
        4'b1110: ascii_byte = 8'h65; // "e"     
        4'b1111: ascii_byte = 8'h66; // "f"
        default: ascii_byte = 8'h30; // "0"
        endcase
    end
   
///////////////////////////////////////////////////////////////////////////	
//  Purpose is to transmit digits (ASCII bytes) to the uart xmitter
//  when word update occurs.
//  Add fifo to hold the ascii bytes to be transmitted by the uart.
//  handshake to uart is tx_dv and return is tx_done. Data is tx_byte.
//  when word_change is true 1) fill fifo with ascii bytes, 2) append EOL
//  and set tx_dv true
//  two FSM, both 6-state using single always.
///////////////////////////////////////////////////////////////////////////

  // detect when hex_word changes
  always @(posedge sys_clk)
  begin
    old_hex_word <= hex_word;
  end
  
  // if hex_word changed set word_change
  always @(posedge sys_clk)
  begin
    word_change <=  old_hex_word != hex_word ? 1'b01 : 1'b00;
  end
  
  // FSM for FIFO input
  // when word_change is true, load hex_nibbles into the fifo
  //
  // inputs:  word_change, ascii_byte
  // outputs: wr, EN, hex_nibble, hex_word, data_in, SEND_start
  /////////////////////////////////////////////////////////////////////////
  always @(posedge sys_clk) begin
  if (!rst_n)
  begin
    sm_digit_r <= FIFO_IDLE;
	 wr <= 0;
	 SEND_start <= 0;
	 EN <= 0;   // ??
  end
  else begin
    EN <= 1;
    case (sm_digit_r)
      FIFO_IDLE:
		  begin		
		    SEND_start <= 0;  
		    hex_nibble <= hex_word[15:12];
		    if( word_change == 1'b1 & full != 1'b1)	
	       begin
			    data_in <= ascii_byte;
			    wr <= 1'b01;
			    hex_nibble <= hex_word[11:8];
			    sm_digit_r <= FIFO_DIGIT_0;
		    end
		  end // IDLE
	 
	   FIFO_DIGIT_0:
		  begin
		    wr <= 1'b00;
        if (wr == 1'b00)	
	     begin	  
		    data_in <= ascii_byte;
		    wr <= 1'b01;
		    hex_nibble <= hex_word[7:4];
		    sm_digit_r <= FIFO_DIGIT_1;
		  end
		  end // FIFO_DIGIT_0	 
		  
	   FIFO_DIGIT_1:
		  begin
		  wr <= 1'b00;
		  if( wr == 1'b0)
		  begin
		     data_in <= ascii_byte;
			  wr <= 1'b01;
			  hex_nibble <= hex_word[3:0];
			  sm_digit_r <= FIFO_DIGIT_2;
		  end		  
		  end // FIFO_DIGIT_1	
		  
	   FIFO_DIGIT_2:
		  begin
		  wr <= 1'b00;		  
		  if( wr == 1'b0)
		  begin
		     data_in <= ascii_byte;
			  wr <= 1'b01;
			  hex_nibble <= hex_word[3:0];
			  sm_digit_r <= FIFO_DIGIT_3;
	     end
		  end // FIFO_DIGIT_2
		  
	   FIFO_DIGIT_3:
		  begin
		  wr <= 1'b00;
		  if( wr == 1'b0)
		  begin
		     data_in <= 8'h0a;  // EOL
			  wr <= 1'b01;
			  hex_nibble <= hex_word[3:0];
			  sm_digit_r <= FIFO_NEW_LINE;
	     end		  
		  end // FIFO_DIGIT_3
	 
	   FIFO_NEW_LINE:
		  begin
		  wr <= 1'b00;	  
		  if( wr ==1'b0)
		  begin
	       sm_digit_r <= FIFO_IDLE;
			 SEND_start <= 1'b1;
		  end
		  end // FIFO_NEW_LINE      
	   default:  // at this point all 4 ascii digits are in the fifo
	     sm_digit_r <= FIFO_IDLE;
    endcase 
  end
  end // always
  
  
  // FSM: to send FIFO to uart
  // when uart_start set, start transmitting fifo to uart
  //
  // inputs:  uart_start, `tx_done
  // outputs: tx_dv, rd
  //
  always @(posedge sys_clk) begin
  if (!rst_n)
  begin
    sm_send_r <= SEND_IDLE;
	 tx_dv <= 1'b0;
	 rd <= 0;
  end
  else begin
    tx_dv_dly_1 <= tx_dv;
    case (sm_send_r)
      SEND_IDLE:
		  begin
		    if( SEND_start == 1'b1)	
	         begin	  
				  rd <= 1'b01;              // read byte from FIFO buffer before dv
			     sm_send_r <= SEND_DIGIT_0;
		      end  
		  end // SEND_IDLE
		  
	   SEND_DIGIT_0:	
		  begin 
		    rd <= 1'b0;                   // clear fifo read strobe
			 tx_dv <= 1'b01;               // start serial transfer
		    if(tx_done == 1'b01 )
		    begin
				tx_dv <= 1'b00;
				rd <= 1'b01;
		      sm_send_r <= SEND_DIGIT_1; 		
		    end	  	  
		  end // SEND_DIGIT_0
	
		SEND_DIGIT_1:	
		  begin
		    rd <= 1'b00;
		    tx_dv <= 1'b01;
		    if(tx_done == 1'b1 )
		    begin
		      //fifo data out should be ready here ??
				tx_dv <= 1'b00;
				rd <= 1'b01;
		      sm_send_r <= SEND_DIGIT_2; 		
		    end	  	  		  
		  end // SEND_DIGIT_1
		
		SEND_DIGIT_2:	
		  begin
		    rd <= 1'b00;
		    tx_dv <= 1'b01;
		    if(tx_done == 1'b1 )
		    begin
		      //fifo data out should be ready here ??
				tx_dv <= 1'b00;
				rd <= 1'b01;
		      sm_send_r <= SEND_DIGIT_3; 		
		    end	  	  		  
		  end // SEND_DIGIT_2
		
		SEND_DIGIT_3:	
		  begin 
		  	 rd <= 1'b00;                  // clear rd strobe
		    tx_dv <= 1'b01;               // and set dv true
		    if(tx_done == 1'b1 )   
		    begin		                              
				tx_dv <= 1'b00;             // fifo data out should be ready here ??           
				rd <= 1'b01;
		      sm_send_r <= SEND_NEW_LINE; 		
		    end	  	  		  
		  end // SEND_DIGIT_3
		
		SEND_NEW_LINE:
		  begin 
		  	 rd <= 1'b00;
		    // tx_dv <= 1'b01;            // was 01
		    if(tx_done == 1'b1 )
		    begin
		      //fifo data out should be ready here ??
				tx_dv <= 1'b00;
				rd <= 1'b00;                // no more reads        
		      sm_send_r <= SEND_IDLE; 		
		    end	  	  		  
		  end //SEND_NEW_LINE
				
		default:
         sm_send_r <= SEND_IDLE;
    endcase
  end
  end // always
///////////////////////////////////////////////////////////////////////////

    	    
 // clk boundary crossing on btnU to remove instability
 always @(posedge sys_clk) begin
   btnU_1 <= btnU;
   btnU_2 <= btnU_1;
   btnU_3 <= btnU_2;
 end
   
 always @(posedge sys_clk ) begin 
    Led <= !btnU_3 && !Led && update_1Hz;
    led[0] <= Led;
    led[1] <= locked;
    led[2] <= RsTx;
 end       
 
 assign sys_clk = clk_5MHz; 
 assign clk_50MHz = CLK50MHZ;  
 assign RsTx = tx_serial_o;
    
endmodule

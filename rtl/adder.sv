`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module Adder (	
	  input logic	                    CLK,	
	  input logic	  [FSIZE*2+$clog2(PRIMITIVE_COUNT)-1:0]       A,	
	  input logic	  [FSIZE*2+$clog2(PRIMITIVE_COUNT)-1:0]       B,	
	  output logic	  [FSIZE*2+$clog2(PRIMITIVE_COUNT)-1:0]     P
  );

  logic [FSIZE*2+$clog2(PRIMITIVE_COUNT)-1:0] add_res_in;
  FifoBuffer #(.DATA_SIZE(FSIZE*2+$clog2(PRIMITIVE_COUNT)), .CYCLES(ADDER_LATENCY) )  mul_res_fifo (.clk(CLK), .rstn(1), .in(add_res_in), .out(P));

  assign add_res_in = A + B;

endmodule

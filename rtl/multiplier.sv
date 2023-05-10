`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;


module Multiplier (	
	  input logic	                    CLK,	
	  input logic	  [FSIZE-1:0]       A,	
	  input logic	  [FSIZE-1:0]       B,	
	  output logic	  [FSIZE*2-1:0]     P
  );

  logic [FSIZE*2-1:0] mul_res_in;
  FifoBuffer #(.DATA_SIZE(FSIZE*2), .CYCLES(MULTIPLIER_LATENCY) )  mul_res_fifo (.clk(CLK), .rstn(1), .in(mul_res_in), .out(P));

  assign mul_res_in = A * B;

endmodule


`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;


module FifoBuffer #(
		parameter DATA_SIZE     = FSIZE,
		parameter integer CYCLES        = 2
	) (	
	  input logic	                        clk,	
	  input logic	                        rstn,	
    input logic   [DATA_SIZE-1:0]       in,
    output logic  [DATA_SIZE-1:0]       out
  );

  typedef struct packed {   
    logic [CYCLES-1:0][DATA_SIZE-1:0] data;
  } Registers;
  
  Registers reg_current,reg_next;
  
  always_comb begin
    reg_next = reg_current;

    reg_next.data[0] = in;

    for(int i = 0; i < CYCLES-1; i ++) begin
      reg_next.data[i+1] = reg_current.data[i];
    end

    if(!rstn) begin
      for(int i = 0; i < CYCLES; i ++) begin
        reg_next.data[i] = 0;
      end
    end
  end

  assign out = reg_current.data[CYCLES-1];
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end
endmodule

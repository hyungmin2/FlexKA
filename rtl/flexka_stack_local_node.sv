`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module flexka_stack_local_node (
		input logic	clk,		    		
		input logic rstn,			

    input logic push,
    input logic pop,
    
    input logic[SSIZE-1:0] in_size_A2,
    input logic[SSIZE-1:0] in_size_B2,
    
    output logic[SSIZE-1:0] size_A2,
    output logic[SSIZE-1:0] size_B2,

    output logic[SSIZE-1:0] depth
	);


  BufferRAMTSsizeInputs size_A2_ram_inputs;
  BufferRAMTSsizeOutputs size_A2_ram_outputs;

  BufferRAMTSsize #(
    .ID(11),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  size_A2_ram(
    .clk(clk),
    .inputs(size_A2_ram_inputs),
    .outputs(size_A2_ram_outputs)
  );


  BufferRAMTSsizeInputs size_B2_ram_inputs;
  BufferRAMTSsizeOutputs size_B2_ram_outputs;

  BufferRAMTSsize #(
    .ID(12),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  size_B2_ram(
    .clk(clk),
    .inputs(size_B2_ram_inputs),
    .outputs(size_B2_ram_outputs)
  );




  // localparam STATE_RUNNING = 1;
  

  
  typedef struct packed {
     logic [31:0] depth;
     logic [31:0] depth_below;
     
     logic [31:0] size_A2;
     logic [31:0] size_B2;
  } Registers;
    
  Registers reg_current,reg_next;

  always_comb begin
    reg_next = reg_current;
    
 

    size_A2_ram_inputs.raddr = reg_current.depth_below;
    size_A2_ram_inputs.waddr = reg_current.depth;
    size_A2_ram_inputs.wdata = in_size_A2;
    size_A2_ram_inputs.wren = push;

    size_B2_ram_inputs.raddr = reg_current.depth_below;
    size_B2_ram_inputs.waddr = reg_current.depth;
    size_B2_ram_inputs.wdata = in_size_B2;
    size_B2_ram_inputs.wren = push;

    size_A2 = reg_current.size_A2;
    size_B2 = reg_current.size_B2;
    
    if(push) begin
      reg_next.depth = reg_current.depth + 1;
      reg_next.depth_below = reg_current.depth_below + 1;
    end
    if(pop) begin
      reg_next.depth = reg_current.depth - 1;
      reg_next.depth_below = reg_current.depth_below - 1;

      reg_next.size_A2 = size_A2_ram_outputs.rdata;
      reg_next.size_B2 = size_B2_ram_outputs.rdata;
    end

    if(rstn == 0) begin
      reg_next.depth = 0;
      reg_next.depth_below = -1;
    end
  end
       
    
  always @ (posedge clk) begin  
    reg_current <= reg_next;
	end
endmodule

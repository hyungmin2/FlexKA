`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module flexka_stack (
		input logic	clk,		    		
		input logic rstn,			

    input logic push,
    input logic pop,
    
    input logic[SSIZE-1:0] in_size_A,
    input logic[SSIZE-1:0] in_size_B,
    input logic[SSIZE-1:0] in_pos_A,
    input logic[SSIZE-1:0] in_pos_B,
    input logic[SSIZE-1:0] in_pos_C,
    input logic[SSIZE-1:0] in_temp_pos_A,
    input logic[SSIZE-1:0] in_temp_pos_B,
    input logic[SSIZE-1:0] in_state,
    input logic[SSIZE-1:0] in_rsize,
    input logic[SSIZE-1:0] in_msize,
    
    output logic[SSIZE-1:0] size_A,
    output logic[SSIZE-1:0] size_B,
    output logic next_go_base_multipler,
    output logic[SSIZE-1:0] pos_A,
    output logic[SSIZE-1:0] pos_B,
    output logic[SSIZE-1:0] pos_C,
    output logic[SSIZE-1:0] pos_C_plus_msize_minus_one,
    output logic[SSIZE-1:0] temp_pos_A,
    output logic[SSIZE-1:0] temp_pos_B,
    output logic[SSIZE-1:0] state,
    output logic[SSIZE-1:0] rsize,
    output logic[SSIZE-1:0] msize,

    output logic[SSIZE-1:0] depth
	);



  
  BufferRAMTSsizeInputs size_Mem_A_inputs;
  BufferRAMTSsizeOutputs size_Mem_A_outputs;

  BufferRAMTSsize #(
    .ID(3),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  size_Mem_A(
    .clk(clk),
    .inputs(size_Mem_A_inputs),
    .outputs(size_Mem_A_outputs)
  );


  BufferRAMTSsizeInputs size_B_ram_inputs;
  BufferRAMTSsizeOutputs size_B_ram_outputs;

  BufferRAMTSsize #(
    .ID(4),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  size_B_ram(
    .clk(clk),
    .inputs(size_B_ram_inputs),
    .outputs(size_B_ram_outputs)
  );





  BufferRAMTSsizeInputs pos_Mem_A_inputs;
  BufferRAMTSsizeOutputs pos_Mem_A_outputs;

  BufferRAMTSsize #(
    .ID(5),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  pos_Mem_A(
    .clk(clk),
    .inputs(pos_Mem_A_inputs),
    .outputs(pos_Mem_A_outputs)
  );





  BufferRAMTSsizeInputs pos_B_ram_inputs;
  BufferRAMTSsizeOutputs pos_B_ram_outputs;

  BufferRAMTSsize #(
    .ID(6),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  pos_B_ram(
    .clk(clk),
    .inputs(pos_B_ram_inputs),
    .outputs(pos_B_ram_outputs)
  );




  BufferRAMTSsizeInputs pos_Mem_C_inputs;
  BufferRAMTSsizeOutputs pos_Mem_C_outputs;

  BufferRAMTSsize #(
    .ID(7),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  pos_Mem_C(
    .clk(clk),
    .inputs(pos_Mem_C_inputs),
    .outputs(pos_Mem_C_outputs)
  );



  BufferRAMTSsizeInputs temp_pos_Mem_A_inputs;
  BufferRAMTSsizeOutputs temp_pos_Mem_A_outputs;

  BufferRAMTSsize #(
    .ID(8),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  temp_pos_Mem_A(
    .clk(clk),
    .inputs(temp_pos_Mem_A_inputs),
    .outputs(temp_pos_Mem_A_outputs)
  );



  BufferRAMTSsizeInputs temp_pos_B_ram_inputs;
  BufferRAMTSsizeOutputs temp_pos_B_ram_outputs;

  BufferRAMTSsize #(
    .ID(9),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  temp_pos_B_ram(
    .clk(clk),
    .inputs(temp_pos_B_ram_inputs),
    .outputs(temp_pos_B_ram_outputs)
  );


  BufferRAMTSsizeInputs state_ram_inputs;
  BufferRAMTSsizeOutputs state_ram_outputs;

  BufferRAMTSsize #(
    .ID(10),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  state_ram(
    .clk(clk),
    .inputs(state_ram_inputs),
    .outputs(state_ram_outputs)
  );



  BufferRAMTSsizeInputs rsize_ram_inputs;
  BufferRAMTSsizeOutputs rsize_ram_outputs;

  BufferRAMTSsize #(
    .ID(10),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  rsize_ram(
    .clk(clk),
    .inputs(rsize_ram_inputs),
    .outputs(rsize_ram_outputs)
  );

  BufferRAMTSsizeInputs msize_ram_inputs;
  BufferRAMTSsizeOutputs msize_ram_outputs;

  BufferRAMTSsize #(
    .ID(10),
    .DEPTH(STACK_BUFFER_SIZE),
    .READ_LATENCY(1)
  )  msize_ram(
    .clk(clk),
    .inputs(msize_ram_inputs),
    .outputs(msize_ram_outputs)
  );



  // localparam STATE_RUNNING = 1;
  

  
  typedef struct packed {
    logic [31:0] depth;
    logic [31:0] depth_below;
    logic [31:0] next_depth;

    logic[SSIZE-1:0] size_A;
    logic[SSIZE-1:0] size_B;
    logic next_go_base_multipler;
    logic[SSIZE-1:0] pos_A;
    logic[SSIZE-1:0] pos_B;
    logic[SSIZE-1:0] pos_C;
    logic[SSIZE-1:0] pos_C_plus_msize_minus_one;
    logic[SSIZE-1:0] temp_pos_A;
    logic[SSIZE-1:0] temp_pos_B;
    logic[SSIZE-1:0] state;
    logic[SSIZE-1:0] rsize;
    logic[SSIZE-1:0] msize;
  } Registers;
    
  Registers reg_current,reg_next;

  always_comb begin
    reg_next = reg_current;
    
    size_Mem_A_inputs.raddr = reg_current.depth_below;
    size_Mem_A_inputs.waddr = reg_current.next_depth;
    size_Mem_A_inputs.wdata = in_size_A;
    size_Mem_A_inputs.wren = push;

    size_B_ram_inputs.raddr = reg_current.depth_below;
    size_B_ram_inputs.waddr = reg_current.next_depth;
    size_B_ram_inputs.wdata = in_size_B;
    size_B_ram_inputs.wren = push;


    pos_Mem_A_inputs.raddr = reg_current.depth_below;
    pos_Mem_A_inputs.waddr = reg_current.next_depth;
    pos_Mem_A_inputs.wdata = in_pos_A;
    pos_Mem_A_inputs.wren = push;

    pos_B_ram_inputs.raddr = reg_current.depth_below;
    pos_B_ram_inputs.waddr = reg_current.next_depth;
    pos_B_ram_inputs.wdata = in_pos_B;
    pos_B_ram_inputs.wren = push;

    pos_Mem_C_inputs.raddr = reg_current.depth_below;
    pos_Mem_C_inputs.waddr = reg_current.next_depth;
    pos_Mem_C_inputs.wdata = in_pos_C;
    pos_Mem_C_inputs.wren = push;

    temp_pos_Mem_A_inputs.raddr = reg_current.depth_below;
    temp_pos_Mem_A_inputs.waddr = reg_current.next_depth;
    temp_pos_Mem_A_inputs.wdata = in_temp_pos_A;
    temp_pos_Mem_A_inputs.wren = push;

    temp_pos_B_ram_inputs.raddr = reg_current.depth_below;
    temp_pos_B_ram_inputs.waddr = reg_current.next_depth;
    temp_pos_B_ram_inputs.wdata = in_temp_pos_B;
    temp_pos_B_ram_inputs.wren = push;

    state_ram_inputs.raddr = reg_current.depth_below;
    state_ram_inputs.waddr = reg_current.next_depth;
    state_ram_inputs.wdata = in_state;
    state_ram_inputs.wren = push;

    rsize_ram_inputs.raddr = reg_current.depth_below;
    rsize_ram_inputs.waddr = reg_current.next_depth;
    rsize_ram_inputs.wdata = in_rsize;
    rsize_ram_inputs.wren = push;

    msize_ram_inputs.raddr = reg_current.depth_below;
    msize_ram_inputs.waddr = reg_current.next_depth;
    msize_ram_inputs.wdata = in_msize;
    msize_ram_inputs.wren = push;

    // size_A = size_Mem_A_outputs.rdata;
    // size_B = size_B_ram_outputs.rdata;
    // pos_A = pos_Mem_A_outputs.rdata;
    // pos_B = pos_B_ram_outputs.rdata;
    // pos_C = pos_Mem_C_outputs.rdata;
    // temp_pos_A = temp_pos_Mem_A_outputs.rdata;
    // temp_pos_B = temp_pos_B_ram_outputs.rdata;
    // state = state_ram_outputs.rdata;
    
    size_A = reg_current.size_A;
    size_B = reg_current.size_B;
    next_go_base_multipler = reg_current.next_go_base_multipler;
    pos_A = reg_current.pos_A;
    pos_B = reg_current.pos_B;
    pos_C = reg_current.pos_C;
    pos_C_plus_msize_minus_one = reg_current.pos_C_plus_msize_minus_one;
    temp_pos_A = reg_current.temp_pos_A;
    temp_pos_B = reg_current.temp_pos_B;
    state = reg_current.state;
    depth = reg_current.depth;
    rsize = reg_current.rsize;
    msize = reg_current.msize;

    if(push) begin
      reg_next.depth = reg_current.depth + 1;
      reg_next.depth_below = reg_current.depth_below + 1;
      reg_next.next_depth = reg_current.next_depth + 1;

      reg_next.size_A = in_size_A;
      reg_next.size_B = in_size_B;
      reg_next.pos_A = in_pos_A;
      reg_next.pos_B = in_pos_B;
      reg_next.pos_C = in_pos_C;
      reg_next.pos_C_plus_msize_minus_one = in_pos_C+in_msize-1;
      reg_next.temp_pos_A = in_temp_pos_A;
      reg_next.temp_pos_B = in_temp_pos_B;
      reg_next.state = in_state;
      
      reg_next.rsize = in_rsize;
      reg_next.msize = in_msize;

      reg_next.next_go_base_multipler = 0;
      if( in_size_A <=  PRIMITIVE_COUNT || in_size_B <= PRIMITIVE_COUNT) begin
        reg_next.next_go_base_multipler = 1;
      end
      // if($time()%2==0) $display("stack_push in_state:%d in_size_A:%d depth:%d depth_below:%d next_depth:%d at %d",in_state,in_size_A,reg_current.depth,reg_current.depth_below,reg_current.next_depth,$time()/2) ; 
    end
    if(pop) begin
      reg_next.depth = reg_current.depth - 1;
      reg_next.depth_below = reg_current.depth_below -1;
      reg_next.next_depth = reg_current.next_depth - 1;

      reg_next.size_A = size_Mem_A_outputs.rdata;
      reg_next.size_B = size_B_ram_outputs.rdata;
      reg_next.pos_A = pos_Mem_A_outputs.rdata;
      reg_next.pos_B = pos_B_ram_outputs.rdata;
      reg_next.pos_C = pos_Mem_C_outputs.rdata;
      reg_next.pos_C_plus_msize_minus_one = pos_Mem_C_outputs.rdata+msize_ram_outputs.rdata-1;
      reg_next.temp_pos_A = temp_pos_Mem_A_outputs.rdata;
      reg_next.temp_pos_B = temp_pos_B_ram_outputs.rdata;
      reg_next.state = state_ram_outputs.rdata;

      reg_next.rsize = rsize_ram_outputs.rdata;
      reg_next.msize = msize_ram_outputs.rdata;
      reg_next.next_go_base_multipler = 0;

      if( in_size_A <=  PRIMITIVE_COUNT || in_size_B <= PRIMITIVE_COUNT) begin
        reg_next.next_go_base_multipler = 1;
      end

      // if($time()%2==0) $display("stack_pop new state:%d new size_A:%d depth:%d depth_below:%d next_depth:%d at %d",state_ram_outputs.rdata,size_Mem_A_outputs.rdata,reg_current.depth,reg_current.depth_below,reg_current.next_depth,$time()/2) ; 
    end

    if(rstn == 0) begin
      reg_next.depth = -1;
      reg_next.depth_below = -2;
      reg_next.next_depth = 0;
    end
  end
       
    
  always @ (posedge clk) begin  
    reg_current <= reg_next;
	end
endmodule

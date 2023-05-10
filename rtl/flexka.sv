`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

`define MIN(x,y) ( ( (x) < (y) ) ? (x) : (y) )


module flexka (
		input logic	clk,		    		
		input logic rstn,			

    input CommandDataPort commanddataport,

    output logic [FSIZE-1:0] flexka_state,
    output logic [FSIZE-1:0] out_data_port,
    output logic [FSIZE-1:0] elapsed_cycles_port
	);

  BufferRAMTFsizeInputsR2W1 Mem_A_inputs;
  logic [FSIZE-1:0] Mem_A_outputs_rdata0;
  logic [FSIZE-1:0] Mem_A_outputs_rdata1;

  BufferRAMTFsizeR2W1 #(
    .ID(0),
    .DEPTH(IN_BUFFER_SIZE)
  )  Mem_A(
    .clk(clk),
    .inputs(Mem_A_inputs),
    .rdata0(Mem_A_outputs_rdata0),
    .rdata1(Mem_A_outputs_rdata1)
  );


  BufferRAMTFsizeInputsR2W1 B_ram_inputs;
  logic [FSIZE-1:0] B_ram_outputs_rdata0;
  logic [FSIZE-1:0] B_ram_outputs_rdata1;

  BufferRAMTFsizeR2W1 #(
    .ID(1),
    .DEPTH(IN_BUFFER_SIZE)
  )  Mem_B(
    .clk(clk),
    .inputs(B_ram_inputs),
    .rdata0(B_ram_outputs_rdata0),
    .rdata1(B_ram_outputs_rdata1)
  );


  BufferRAMTFsizeInputsR4W1 Mem_C_inputs;
  logic [FSIZE-1:0] Mem_C_outputs_rdata0;
  logic [FSIZE-1:0] Mem_C_outputs_rdata1;
  logic [FSIZE-1:0] Mem_C_outputs_rdata2;
  logic [FSIZE-1:0] Mem_C_outputs_rdata3;

  BufferRAMTFsizeR4W1 #(
    .ID(2),
    .DEPTH(OUT_BUFFER_SIZE)
  )  Mem_C(
    .clk(clk),
    .inputs(Mem_C_inputs),
    .rdata0(Mem_C_outputs_rdata0),
    .rdata1(Mem_C_outputs_rdata1),
    .rdata2(Mem_C_outputs_rdata2),
    .rdata3(Mem_C_outputs_rdata3)
  );

  //FlexKA Main FSM states
  localparam STATE_THRESHOLD_CHECK = 1; //TC
  localparam STATE_BASE_MULTIPLIER = 2; //BM - wait until BM finishes
  localparam STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_l = 3; //L-call
  localparam STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h1 = 4; //H-call cycle1
  localparam STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h2 = 5; //H-call cycle2
  localparam STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h3 = 6; //H-call cycle3
  localparam STATE_OPERAND_MERGING_begin = 7; //OM phase1
  localparam STATE_OPERAND_MERGING_wait = 8;  //OM / PNS  - wait until OM finishes
  localparam STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_hl = 9;  //HL_call
  localparam STATE_PARTIAL_PRODUCT_COMBINATION_begin = 10; // PCC
  localparam STATE_PARTIAL_PRODUCT_COMBINATION_wait = 11; // PCC / PNS -  wait until PCC finishes. 
  
  localparam STATE_BITS = $clog2(STATE_PARTIAL_PRODUCT_COMBINATION_wait);  


  //Parameters pushed into the stack
  logic[SSIZE-1:0] stack_in_size_A; //n_A
  logic[SSIZE-1:0] stack_in_size_B; //n_B
  logic[SSIZE-1:0] stack_in_pos_A;  //i_A
  logic[SSIZE-1:0] stack_in_pos_B;  //i_B
  logic[SSIZE-1:0] stack_in_pos_C;  //i_C
  logic[SSIZE-1:0] stack_in_temp_pos_A; //t_A
  logic[SSIZE-1:0] stack_in_temp_pos_B; //t_B
  logic[SSIZE-1:0] stack_in_msize;  //m
  logic[SSIZE-1:0] stack_in_rsize;  //result size
  logic[STATE_BITS-1:0] stack_in_state; //nextState

  typedef struct packed {        
    logic[SSIZE-1:0] in_size_A;
    logic[SSIZE-1:0] in_size_B;
    logic[SSIZE-1:0] in_size_AB;
    logic[SSIZE-1:0] in_size_min_AB;

    logic[SSIZE-1:0] stack_size_A_minus_msize;
    logic[SSIZE-1:0] stack_size_B_minus_msize;
    logic[SSIZE-1:0] stack_in2_size_A;
    logic[SSIZE-1:0] stack_in2_size_B;
    logic[SSIZE-1:0] stack_in2_pos_A;
    logic[SSIZE-1:0] stack_in2_pos_B;
    logic[SSIZE-1:0] stack_in2_pos_C;
    logic[SSIZE-1:0] stack_in2_temp_pos_A;
    logic[SSIZE-1:0] stack_in2_temp_pos_B;
    logic[SSIZE-1:0] stack_in2_msize;
    logic[SSIZE-1:0] stack_in2_rsize;

    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_raddr0;
    logic [STATE_BITS-1:0] state;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] in_addr_A;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] in_addr_B;
    
    logic [2:0] command;
    logic [FSIZE-1:0] command_data0;
    logic [FSIZE-1:0] command_data1;

    logic stack_push;

    logic [FSIZE-1:0] counter;
  } Registers;
    
  Registers reg_current,reg_next;

  logic stack_push;
  logic stack_pop;  

  //parameters popped from stack
  logic[SSIZE-1:0] stack_size_A;  // n_A
  logic[SSIZE-1:0] stack_size_B;  // n_B
  logic[SSIZE-1:0] stack_pos_A;  // i_A
  logic[SSIZE-1:0] stack_pos_B;  // i_B
  logic[SSIZE-1:0] stack_pos_C;  // i_C
  logic[SSIZE-1:0] stack_pos_C_plus_msize_minus_one;  //i_C + m -1  (precomputed for better timing...)
  logic[SSIZE-1:0] stack_temp_pos_A; // t_A
  logic[SSIZE-1:0] stack_temp_pos_B; // t_B
  logic[FSIZE-1:0] stack_state; //FSM current state

  logic[SSIZE-1:0] stack_depth; //"level"

  logic[SSIZE-1:0] localsave_size_A2; 
  logic[SSIZE-1:0] localsave_size_B2;
  logic[SSIZE-1:0] localsave_depth;

  logic [SSIZE-1:0] rsize;
  logic [SSIZE-1:0] msize;
  logic next_go_base_multipler;

  flexka_stack flexka_stack (
    .clk(clk),
    .rstn(rstn),
    .push(stack_push),
    .pop(stack_pop),

    .in_size_A(stack_in_size_A),
    .in_size_B(stack_in_size_B),	
    .in_pos_A(stack_in_pos_A),	
    .in_pos_B(stack_in_pos_B),	
    .in_pos_C(stack_in_pos_C),	
    .in_temp_pos_A(stack_in_temp_pos_A),	
    .in_temp_pos_B(stack_in_temp_pos_B),	
    .in_msize(stack_in_msize),	
    .in_rsize(stack_in_rsize),	
    .in_state(stack_in_state),	
    
    .size_A(stack_size_A),
    .size_B(stack_size_B),	
    .next_go_base_multipler(next_go_base_multipler),
    .pos_A(stack_pos_A),	
    .pos_B(stack_pos_B),	
    .pos_C(stack_pos_C),	
    .pos_C_plus_msize_minus_one(stack_pos_C_plus_msize_minus_one),	
    .temp_pos_A(stack_temp_pos_A),	
    .temp_pos_B(stack_temp_pos_B),	
    .state(stack_state),	

    .rsize(rsize),
    .msize(msize),

    .depth(stack_depth)
	);

  flexka_stack_local_node flexka_stack_local_node (
    .clk(clk),
    .rstn(rstn),
    .push(stack_push),
    .pop(stack_pop),

    .in_size_A2(localsave_in_size_A2),
    .in_size_B2(localsave_in_size_B2),	

    .size_A2(localsave_size_A2),
    .size_B2(localsave_size_B2),	

    .depth(localsave_depth)
	);

  logic PCC_start;
  logic PCC_done;
  logic Mem_C_inputs_read_valid_PCC;
  BufferRAMTFsizeInputsR4W1 Mem_C_inputs_PCC;

  flexka_partial_product_combination flexka_partial_product_combination (
    .clk(clk),
    .rstn(rstn),
    
    .rsize(rsize),
    .msize(msize),
    .stack_size_A(stack_size_A),
    .stack_size_B(stack_size_B),
    .stack_pos_C(stack_pos_C),
    .stack_pos_C_plus_msize_minus_one(stack_pos_C_plus_msize_minus_one),
    .localsave_size_A2(localsave_size_A2),
    .localsave_size_B2(localsave_size_B2),
  
    .PCC_start(PCC_start),
    .PCC_done(PCC_done),

    .Mem_C_inputs_read_valid(Mem_C_inputs_read_valid_PCC),
    .Mem_C_inputs(Mem_C_inputs_PCC),
    .Mem_C_outputs_rdata0(Mem_C_outputs_rdata0),
    .Mem_C_outputs_rdata1(Mem_C_outputs_rdata1),
    .Mem_C_outputs_rdata2(Mem_C_outputs_rdata2),
    .Mem_C_outputs_rdata3(Mem_C_outputs_rdata3)
  );

  logic OM_A_start;
  logic HL_call_A_is_ready;
  logic Mem_A_inputs_read_valid_OM;
  BufferRAMTFsizeInputsR2W1 Mem_A_inputs_OM;
  logic[SSIZE-1:0] localsave_in_size_A2;

  flexka_operand_merging #(.IS_A(1)) flexka_operand_merging_A (
    .clk(clk),
    .rstn(rstn),
    
    .msize(msize),
    .stack_pos(stack_pos_A),
    .stack_size(stack_size_A),
    .stack_temp_pos(stack_temp_pos_A),

    .OM_start(OM_A_start),
    .OM_done(HL_call_A_is_ready),

    .ram_inputs_read_valid(Mem_A_inputs_read_valid_OM),
    .ram_inputs(Mem_A_inputs_OM),
    .ram_outputs_rdata0(Mem_A_outputs_rdata0),
    .ram_outputs_rdata1(Mem_A_outputs_rdata1),
    
    .localsave_in_size_2(localsave_in_size_A2)
  );


  logic OM_B_start;
  logic HL_call_B_is_ready;
  logic B_ram_inputs_read_valid_OM;
  BufferRAMTFsizeInputsR2W1 B_ram_inputs_OM;
  logic[SSIZE-1:0] localsave_in_size_B2;

  flexka_operand_merging #(.IS_A(0)) flexka_operand_merging_B (
    .clk(clk),
    .rstn(rstn),
    
    .msize(msize),
    .stack_pos(stack_pos_B),
    .stack_size(stack_size_B),
    .stack_temp_pos(stack_temp_pos_B),

    .OM_start(OM_B_start),
    .OM_done(HL_call_B_is_ready),

    .ram_inputs_read_valid(B_ram_inputs_read_valid_OM),
    .ram_inputs(B_ram_inputs_OM),
    .ram_outputs_rdata0(B_ram_outputs_rdata0),
    .ram_outputs_rdata1(B_ram_outputs_rdata1),
    
    .localsave_in_size_2(localsave_in_size_B2)
  );

  

  logic BM_start;
  logic BM_done;
  logic Mem_A_inputs_read_valid_BM;
  logic B_ram_inputs_read_valid_BM;
  BufferRAMTFsizeInputsR2W1 Mem_A_inputs_BM;
  BufferRAMTFsizeInputsR2W1 B_ram_inputs_BM;
  BufferRAMTFsizeInputsR4W1 Mem_C_inputs_BM;

  flexka_base_multiplier flexka_base_multiplier (
    .clk(clk),
    .rstn(rstn),
    
    .rsize(rsize),
    .stack_size_A(stack_size_A),
    .stack_size_B(stack_size_B),
    .stack_pos_A(stack_pos_A),
    .stack_pos_B(stack_pos_B),
    .stack_pos_C(stack_pos_C),

    .BM_start(BM_start),
    .BM_done(BM_done),

    .Mem_A_inputs_read_valid(Mem_A_inputs_read_valid_BM),
    .B_ram_inputs_read_valid(B_ram_inputs_read_valid_BM),
    .Mem_A_inputs(Mem_A_inputs_BM),
    .B_ram_inputs(B_ram_inputs_BM),
    .Mem_C_inputs(Mem_C_inputs_BM),
    .Mem_A_outputs_rdata0(Mem_A_outputs_rdata0),
    .B_ram_outputs_rdata0(B_ram_outputs_rdata0)
  );


  
  localparam VALID_IDLE = 0;

  
  always_comb begin
    reg_next = reg_current;
    
    //Default wire values to prevent latches
    Mem_A_inputs.raddr0 = 0;
    Mem_A_inputs.raddr1 = 0;
    Mem_A_inputs.waddr = reg_current.in_addr_A;
    Mem_A_inputs.wdata = reg_current.command_data0;
    Mem_A_inputs.wren = 0;

    B_ram_inputs.raddr0 = 0;
    B_ram_inputs.raddr1 = 0;
    B_ram_inputs.waddr = reg_current.in_addr_B;
    B_ram_inputs.wdata = reg_current.command_data0;
    B_ram_inputs.wren = 0;

    Mem_C_inputs.raddr0 = reg_current.C_raddr0;    
    Mem_C_inputs.raddr1 = 0;
    Mem_C_inputs.raddr2 = 0;
    Mem_C_inputs.raddr3 = 0;
    Mem_C_inputs.waddr = 0;
    Mem_C_inputs.wdata = 0;
    Mem_C_inputs.wren = 0;

    flexka_state = reg_current.state;
    out_data_port = Mem_C_outputs_rdata0;
    elapsed_cycles_port = reg_current.counter;

    stack_push = 0;
    stack_pop = 0;

    //Handle input commands from the software interface
    
    reg_next.command = 0;
    if(commanddataport.valid) begin
      reg_next.command = commanddataport.command;
      reg_next.command_data0 = commanddataport.data0;
      reg_next.command_data1 = commanddataport.data1;
    end

    //Receive input size parameters
    if(reg_current.command == COMMAND_KARATSUBA_SIZE_A) begin
      reg_next.in_size_A = reg_current.command_data0;
      reg_next.in_addr_A = 0;
      reg_next.in_size_AB = reg_current.in_size_B + reg_current.command_data0;      
      reg_next.in_size_min_AB = `MIN(reg_current.in_size_B,reg_current.command_data0);      
    end
    if(reg_current.command == COMMAND_KARATSUBA_SIZE_B) begin
      reg_next.in_size_B = reg_current.command_data0;      
      reg_next.in_addr_B = 0;
      reg_next.in_size_AB = reg_current.in_size_A + reg_current.command_data0;      
      reg_next.in_size_min_AB = `MIN(reg_current.in_size_A,reg_current.command_data0);      
    end
    
    //Receive input data (sequentially)
    if(reg_current.command == COMMAND_KARATSUBA_DATA_A) begin
      Mem_A_inputs.wren = 1;
      reg_next.in_addr_A = reg_current.in_addr_A+1;
    end
    if(reg_current.command == COMMAND_KARATSUBA_DATA_B) begin
      B_ram_inputs.wren = 1;
      reg_next.in_addr_B = reg_current.in_addr_B+1;
    end

    //Retrieve computation results
    if(reg_current.command == COMMAND_KARATSUBA_OUTADDR) begin
      reg_next.C_raddr0 = reg_current.command_data0;
    end

    //Launch FlexKA computation
    if(reg_current.command == COMMAND_KARATSUBA) begin
      reg_next.stack_in2_size_A = reg_current.in_size_A;
      reg_next.stack_in2_size_B = reg_current.in_size_B;
      reg_next.stack_in2_pos_A = 0;
      reg_next.stack_in2_pos_B = 0;
      reg_next.stack_in2_pos_C = 0;
      reg_next.stack_in2_temp_pos_A = reg_current.in_size_A;
      reg_next.stack_in2_temp_pos_B = reg_current.in_size_B;
      reg_next.stack_in2_msize = reg_current.in_size_min_AB / 2;
      reg_next.stack_in2_rsize = reg_current.in_size_AB;

      reg_next.stack_push = 1;

      reg_next.counter = 0;
    end

    //Record FlexKA computation cycles until returns to IDLE
    if(reg_current.state!=STATE_IDLE) begin
      reg_next.counter = reg_current.counter +1;
    end

    stack_in_state = STATE_IDLE;
    if(reg_current.stack_push) begin
      stack_push = 1;

      reg_next.stack_push = 0;
      reg_next.state = STATE_THRESHOLD_CHECK;
    end
    


    //
    //FlexKA MAIN FSM - begin
    //


    //TC: Threshold Check
    BM_start = 0;  
    if(reg_current.state == STATE_THRESHOLD_CHECK) begin
      if( next_go_base_multipler) begin
        BM_start = 1;
        reg_next.state = STATE_BASE_MULTIPLIER;  
      end
      else begin
        reg_next.stack_in2_size_A = msize;
        reg_next.stack_in2_size_B = msize;
        reg_next.stack_in2_pos_A = stack_pos_A;
        reg_next.stack_in2_pos_B = stack_pos_B;
        reg_next.stack_in2_pos_C = stack_pos_C + msize;
        reg_next.stack_in2_temp_pos_A = stack_temp_pos_A;
        reg_next.stack_in2_temp_pos_B = stack_temp_pos_B;
        reg_next.stack_in2_msize = msize / 2;
        reg_next.stack_in2_rsize = msize * 2;


        reg_next.state = STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_l;
      end
    end

    //L-call: Call lower-level node for AB_l computaiton 
    stack_in_size_A = reg_current.stack_in2_size_A;
    stack_in_size_B = reg_current.stack_in2_size_B;
    stack_in_pos_A = reg_current.stack_in2_pos_A;
    stack_in_pos_B = reg_current.stack_in2_pos_B;
    stack_in_pos_C = reg_current.stack_in2_pos_C;
    stack_in_temp_pos_A = reg_current.stack_in2_temp_pos_A;
    stack_in_temp_pos_B = reg_current.stack_in2_temp_pos_B;
    stack_in_msize = reg_current.stack_in2_msize;
    stack_in_rsize = reg_current.stack_in2_rsize;
    
    if(reg_current.state == STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_l) begin
      stack_in_state = STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h1;

      stack_push = 1;
      reg_next.state = STATE_THRESHOLD_CHECK;
    end

    if(reg_current.state == STATE_BASE_MULTIPLIER) begin
      if(BM_done) begin
        reg_next.state = stack_state;
        stack_pop = 1;
      end
    end

    //H-call: Call lower-level node for AB_h computaiton 
    if(reg_current.state == STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h1) begin
      reg_next.stack_size_A_minus_msize = stack_size_A - msize;
      reg_next.stack_size_B_minus_msize = stack_size_B - msize;
      reg_next.state = STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h2;
    end
    if(reg_current.state == STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h2) begin
      reg_next.stack_in2_size_A = reg_current.stack_size_A_minus_msize;
      reg_next.stack_in2_size_B = reg_current.stack_size_B_minus_msize;
      reg_next.stack_in2_pos_A = stack_pos_A + msize;
      reg_next.stack_in2_pos_B = stack_pos_B + msize;
      reg_next.stack_in2_pos_C = stack_pos_C + msize*2 + msize;
      reg_next.stack_in2_temp_pos_A = stack_temp_pos_A;
      reg_next.stack_in2_temp_pos_B = stack_temp_pos_B;
      reg_next.stack_in2_msize = (`MIN(reg_current.stack_size_A_minus_msize,reg_current.stack_size_B_minus_msize)) >> 1;
      reg_next.stack_in2_rsize = reg_current.stack_size_A_minus_msize + reg_current.stack_size_B_minus_msize;

      reg_next.state = STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h3;
    end
    if(reg_current.state == STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_h3) begin
      stack_in_state = STATE_OPERAND_MERGING_begin;

      stack_push = 1;
      reg_next.state = STATE_THRESHOLD_CHECK;
    end

    //OM: Operand Merging
    OM_A_start = 0;
    OM_B_start = 0;
    if(reg_current.state == STATE_OPERAND_MERGING_begin) begin
      OM_A_start = 1;
      OM_B_start = 1;
      reg_next.state = STATE_OPERAND_MERGING_wait;
    end

    if(reg_current.state == STATE_OPERAND_MERGING_wait) begin
      if(HL_call_A_is_ready && HL_call_B_is_ready) begin
        //HL-call: Call lower-level node for AB_hl computaiton 
        reg_next.stack_in2_size_A = localsave_in_size_A2;
        reg_next.stack_in2_size_B = localsave_in_size_B2;
        reg_next.stack_in2_pos_A = stack_temp_pos_A;
        reg_next.stack_in2_pos_B = stack_temp_pos_B;
        reg_next.stack_in2_pos_C = stack_pos_C + rsize + msize;
        reg_next.stack_in2_temp_pos_A = stack_temp_pos_A + localsave_in_size_A2;
        reg_next.stack_in2_temp_pos_B = stack_temp_pos_B + localsave_in_size_B2;
        reg_next.stack_in2_msize = `MIN(localsave_in_size_A2,localsave_in_size_B2) / 2;
        reg_next.stack_in2_rsize = localsave_in_size_A2 + localsave_in_size_B2;

        reg_next.state = STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_hl;
      end
    end
    if(reg_current.state == STATE_CALL_LOWER_LEVEL_KARATSUBA_AB_hl) begin
        stack_in_state = STATE_PARTIAL_PRODUCT_COMBINATION_begin;
        stack_push = 1;

        reg_next.state = STATE_THRESHOLD_CHECK;      
    end
        
    //PCC: partial product combination
    PCC_start = 0;
    if(reg_current.state == STATE_PARTIAL_PRODUCT_COMBINATION_begin) begin
      PCC_start = 1;
      reg_next.state = STATE_PARTIAL_PRODUCT_COMBINATION_wait;
    end
      
    if(reg_current.state == STATE_PARTIAL_PRODUCT_COMBINATION_wait) begin
      if(PCC_done) begin
        reg_next.state = stack_state;
        stack_pop = 1;
      end
    end

    //
    //FlexKA MAIN FSM - end
    //


    //Connect Memory inputs from OM, PCC, BM modules
    Mem_A_inputs.raddr0 = Mem_A_inputs_OM.raddr0;    
    Mem_A_inputs.raddr1 = Mem_A_inputs_OM.raddr1;
    if(Mem_A_inputs_OM.wren) begin
      Mem_A_inputs.wren = 1;
      Mem_A_inputs.waddr = Mem_A_inputs_OM.waddr;
      Mem_A_inputs.wdata = Mem_A_inputs_OM.wdata;
    end

    B_ram_inputs.raddr0 = B_ram_inputs_OM.raddr0;    
    B_ram_inputs.raddr1 = B_ram_inputs_OM.raddr1;
    if(B_ram_inputs_OM.wren) begin
      B_ram_inputs.wren = 1;
      B_ram_inputs.waddr = B_ram_inputs_OM.waddr;
      B_ram_inputs.wdata = B_ram_inputs_OM.wdata;
    end

    if(Mem_C_inputs_read_valid_PCC) begin
      Mem_C_inputs.raddr0 = Mem_C_inputs_PCC.raddr0;    
    end

    Mem_C_inputs.raddr1 = Mem_C_inputs_PCC.raddr1;
    Mem_C_inputs.raddr2 = Mem_C_inputs_PCC.raddr2;
    Mem_C_inputs.raddr3 = Mem_C_inputs_PCC.raddr3;

    Mem_C_inputs.wren = Mem_C_inputs_PCC.wren;
    Mem_C_inputs.waddr = Mem_C_inputs_PCC.waddr;
    Mem_C_inputs.wdata = Mem_C_inputs_PCC.wdata;
  

    if(Mem_A_inputs_read_valid_BM) begin
      Mem_A_inputs.raddr0 = Mem_A_inputs_BM.raddr0;    
    end
    if(B_ram_inputs_read_valid_BM) begin
      B_ram_inputs.raddr0 = B_ram_inputs_BM.raddr0;    
    end
    if(Mem_C_inputs_BM.wren) begin
      Mem_C_inputs.wren = 1;
      Mem_C_inputs.waddr = Mem_C_inputs_BM.waddr;
      Mem_C_inputs.wdata = Mem_C_inputs_BM.wdata;
    end


    if(rstn == 0) begin
      reg_next.state = STATE_IDLE;
    end
  end
       
    
  always @ (posedge clk) begin  
    reg_current <= reg_next;
	end
endmodule

`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module flexka_partial_product_combination (
		input logic	clk,		    		
		input logic rstn,			

    input logic [SSIZE-1:0] rsize,
    input logic [SSIZE-1:0] msize,
    input logic [SSIZE-1:0] stack_size_A,
    input logic [SSIZE-1:0] stack_size_B,
    input logic [SSIZE-1:0] stack_pos_C,
    input logic [SSIZE-1:0] stack_pos_C_plus_msize_minus_one,
    input logic [SSIZE-1:0] localsave_size_A2,
    input logic [SSIZE-1:0] localsave_size_B2,
  
    input logic PCC_start,
    output logic PCC_done,
    
    output logic Mem_C_inputs_read_valid,
    output BufferRAMTFsizeInputsR4W1 Mem_C_inputs,

    input logic [FSIZE-1:0] Mem_C_outputs_rdata0,
    input logic [FSIZE-1:0] Mem_C_outputs_rdata1,
    input logic [FSIZE-1:0] Mem_C_outputs_rdata2,
    input logic [FSIZE-1:0] Mem_C_outputs_rdata3
	);


  typedef struct packed {    
    logic [1:0] state;

    logic [$clog2(OUT_BUFFER_SIZE)-1:0] portPA_idx_to_begin_others;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] portPB_idx_limit;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] portPC_idx_limit;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] portPD_idx_limit;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] portPA_idx_end;
    
    logic sub_z_ready;
    logic sub_z_ready2;
    logic sub_z_valid;
    logic [FSIZE-1:0] loaded_ABhl_word;
    logic [FSIZE-1:0] loaded_ABl_word;
    logic [FSIZE-1:0] loaded_ABh_word;
    logic [FSIZE-1:0] loaded_ABhABl_word;
    logic [FSIZE+2:0] sub_z_res;
    logic [FSIZE+2:0] sub_z_res_carry;
    logic [1:0] sub_carry;
    logic [1:0] add_carry;

    logic pop_requested;


    logic [$clog2(OUT_BUFFER_SIZE)-1:0] out_data_addr;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] out_data_addr_next;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_raddr0;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_raddr1;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_raddr2;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_raddr3;
    logic ABhABl_first;
    logic ABhABl_last;
    logic load_begin_others;
    logic load_ABhl_exceed_limit;
    logic load_ABl_exceed_limit;
    logic load_ABh_exceed_limit;
  } Registers;
    
   Registers reg_current,reg_next;
  
  localparam VALID_IDLE = 0;
  localparam VALID_PCC = 1;

  localparam STATE_PCC_LOAD = 2;
  localparam STATE_WAIT_PCC = 3;


  logic reset_ctrl_fifos;
  logic [1-1:0] add_valid;
  logic [1-1:0] add_valid_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_valid_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_valid_fifo_in), .out(add_valid));
  logic add_operand_first;
  logic add_operand_first_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_first_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_first_fifo_in), .out(add_operand_first));
  logic add_operand_ABhl_zero;
  logic add_operand_ABhl_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_ABhl_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_ABhl_zero_fifo_in), .out(add_operand_ABhl_zero));
  logic add_operand_ABl_zero;
  logic add_operand_ABl_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_ABl_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_ABl_zero_fifo_in), .out(add_operand_ABl_zero));
  logic add_operand_ABh_zero;
  logic add_operand_ABh_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_ABh_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_ABh_zero_fifo_in), .out(add_operand_ABh_zero));
  logic add_operand_end;
  logic add_operand_end_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_end_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_end_fifo_in), .out(add_operand_end));


  always_comb begin
    //  if($time()%2==0 && reg_current.state!=0) 
    //       $display("FINAL ADD state:%d sA:%d sB:%d m:%d r:%d pC:%d add_valid:%d at %d"
    //             ,reg_current.state,stack_size_A,stack_size_B,msize,rsize
    //             ,stack_pos_C
    //             ,add_valid
    //             ,$time()/2) ; 

    reg_next = reg_current;
    
    Mem_C_inputs.raddr0 = reg_current.C_raddr0;    
    Mem_C_inputs.raddr1 = reg_current.C_raddr1;    
    Mem_C_inputs.raddr2 = reg_current.C_raddr2;    
    Mem_C_inputs.raddr3 = reg_current.C_raddr3;    
    Mem_C_inputs.waddr = reg_current.out_data_addr;    
    Mem_C_inputs.wdata = 0;
    Mem_C_inputs.wren = 0;

    
    add_valid_fifo_in = VALID_IDLE;
    add_operand_first_fifo_in = 0;
    add_operand_ABhl_zero_fifo_in = 0;
    add_operand_ABl_zero_fifo_in = 0;
    add_operand_ABh_zero_fifo_in = 0;
    add_operand_end_fifo_in = 0;

    PCC_done = 0;

    Mem_C_inputs_read_valid = 0;

    reset_ctrl_fifos = 0;

    //drive PCC = (AB_h:AB_l) + AB_hl - AB_l - AB_h
    if(PCC_start) begin
      // Mem_C_inputs_read_valid = 1;

      reg_next.C_raddr0 = stack_pos_C+msize;            //AB_h:AB_h
      reg_next.C_raddr1 = stack_pos_C+msize+rsize;      //AB_hl
      reg_next.C_raddr2 = stack_pos_C+msize+(msize<<1); //-AB_h
      reg_next.C_raddr3 = stack_pos_C+msize;            //-AB_l
      
      reg_next.ABhABl_first = 1;
      reg_next.ABhABl_last = 0;
      if(rsize == 1) begin
        reg_next.ABhABl_last = 1;        
      end
      reg_next.load_begin_others = 0;
      reg_next.load_ABhl_exceed_limit = 0;
      reg_next.load_ABl_exceed_limit = 0;
      reg_next.load_ABh_exceed_limit = 0;

      reg_next.portPA_idx_to_begin_others = stack_pos_C_plus_msize_minus_one+msize;

      reg_next.portPB_idx_limit = stack_pos_C_plus_msize_minus_one+rsize+localsave_size_A2 + localsave_size_B2;
      reg_next.portPC_idx_limit = stack_pos_C_plus_msize_minus_one+(msize<<1);
      reg_next.portPD_idx_limit = stack_pos_C_plus_msize_minus_one+rsize;
      
      reg_next.portPA_idx_end = stack_pos_C_plus_msize_minus_one+rsize;
      
      reg_next.state = STATE_PCC_LOAD;
    end

    if(reg_current.state == STATE_PCC_LOAD) begin      
      Mem_C_inputs_read_valid = 1;
      
      reg_next.C_raddr0 = reg_current.C_raddr0 + 1;
      if(reg_next.C_raddr0 == reg_current.portPA_idx_end) begin
        reg_next.ABhABl_last = 1;
      end
      if(reg_current.C_raddr0 == reg_current.portPA_idx_to_begin_others) begin
        reg_next.load_begin_others = 1;
      end

      add_valid_fifo_in = VALID_PCC;

      if( reg_current.load_begin_others ) begin
        reg_next.C_raddr1 = reg_current.C_raddr1 + 1;
        reg_next.C_raddr2 = reg_current.C_raddr2 + 1;
        reg_next.C_raddr3 = reg_current.C_raddr3 + 1;
      end
      else begin
        add_operand_ABhl_zero_fifo_in = 1;        
        add_operand_ABl_zero_fifo_in = 1;        
        add_operand_ABh_zero_fifo_in = 1;        
      end

      if(reg_current.C_raddr1 == reg_current.portPB_idx_limit) begin
        reg_next.load_ABhl_exceed_limit = 1;
      end
      if(reg_current.C_raddr2 == reg_current.portPD_idx_limit) begin
        reg_next.load_ABh_exceed_limit = 1;
      end
      if(reg_current.C_raddr3 == reg_current.portPC_idx_limit) begin
        reg_next.load_ABl_exceed_limit = 1;
      end

      if(reg_current.ABhABl_first) begin
        reg_next.ABhABl_first = 0;
        add_operand_first_fifo_in = 1;
      end

      if(reg_current.load_ABhl_exceed_limit)
        add_operand_ABhl_zero_fifo_in = 1;        
      if(reg_current.load_ABl_exceed_limit)
        add_operand_ABl_zero_fifo_in = 1;
      if(reg_current.load_ABh_exceed_limit)
        add_operand_ABh_zero_fifo_in = 1;
      
      if(reg_current.ABhABl_last) begin
        reg_next.state = STATE_WAIT_PCC;
        add_operand_end_fifo_in = 1;
      end
    end
      
    if(reg_current.state == STATE_WAIT_PCC) begin
    end

   
    reg_next.sub_z_ready = 0;


    reg_next.loaded_ABhABl_word  = Mem_C_outputs_rdata0;    
    reg_next.loaded_ABhl_word = Mem_C_outputs_rdata1;    
    reg_next.loaded_ABh_word = Mem_C_outputs_rdata2;    
    reg_next.loaded_ABl_word = Mem_C_outputs_rdata3;    
      

      if(add_operand_ABhl_zero) begin
        reg_next.loaded_ABhl_word = 0;
      end
      if(add_operand_ABl_zero) begin
        reg_next.loaded_ABl_word = 0;
      end
      if(add_operand_ABh_zero) begin
        reg_next.loaded_ABh_word = 0;
      end
      
    if(add_valid == VALID_PCC) begin

      // if($time()%2==0) $display("FINAL ADD add_valid at %d",$time()/2) ; 
      reg_next.sub_z_ready = 1;

      if(add_operand_first) begin
        reg_next.sub_carry = 0;
        reg_next.add_carry = 0;
        reg_next.out_data_addr_next = stack_pos_C;        
        reg_next.pop_requested = 0;
      end

      if(add_operand_end) begin
        reg_next.state = STATE_IDLE;
        PCC_done = 1;
        reset_ctrl_fifos = 1;
        reg_next.pop_requested = 1;
        // if($time()%2==0) $display("FINAL ADD requesting state_pop 0 at %d",$time()/2) ; 
      end
    end

    
    reg_next.sub_z_valid = 0;
    
    reg_next.sub_z_res = reg_current.loaded_ABhABl_word + reg_current.loaded_ABhl_word - reg_current.loaded_ABl_word - reg_current.loaded_ABh_word;
    reg_next.sub_z_res_carry = reg_current.sub_z_res - reg_current.sub_carry + reg_current.add_carry ;
    

    reg_next.sub_z_ready2 = 0;
    if(reg_current.sub_z_ready) begin
      reg_next.sub_z_ready2 = 1;

      // if($time()%2==0) $display("ABhABl+ABhl-ABl-ABh %x %x %x %x = %x at %d"
      //       ,reg_current.loaded_ABhABl_word,reg_current.loaded_ABhl_word,reg_current.loaded_ABl_word,reg_current.loaded_ABh_word            
      //       ,reg_next.sub_z_res ,$time()/2) ; 
    end
    if(reg_current.sub_z_ready2) begin

      reg_next.sub_z_valid = 1;
      reg_next.out_data_addr = reg_current.out_data_addr_next;
      reg_next.out_data_addr_next = reg_current.out_data_addr_next + 1;
      
      reg_next.sub_carry = 0;
      reg_next.add_carry = 0;
      if(reg_next.sub_z_res_carry[FSIZE+2] == 1'b1) begin
        if(reg_next.sub_z_res_carry[FSIZE+1:FSIZE] == 2'b10) reg_next.sub_carry = 2;
        else if(reg_next.sub_z_res_carry[FSIZE+1:FSIZE] == 2'b11) reg_next.sub_carry = 1;
      end
      else begin
        if(reg_next.sub_z_res_carry[FSIZE+1:FSIZE] == 2'b01) reg_next.add_carry = 1;
        else if(reg_next.sub_z_res_carry[FSIZE+1:FSIZE] == 2'b10) reg_next.add_carry = 2;
      end

      // if($time()%2==0) $display("z-sc+ac %x %d %d = %x at %d"
      //       ,reg_current.sub_z_res
      //       , reg_current.sub_carry , reg_current.add_carry 
      //       ,reg_next.sub_z_res_carry ,$time()/2) ; 
    end
    
    Mem_C_inputs.waddr = reg_current.out_data_addr;
    Mem_C_inputs.wdata = reg_current.sub_z_res_carry;
    
    if(reg_current.sub_z_valid) begin      
      Mem_C_inputs.wren = 1;

      // if($time()%2==0) $display("sub_z_valid addr:%d val:%x  at %d",reg_current.out_data_addr,Mem_C_inputs.wdata ,$time()/2) ; 
    end



    if(rstn == 0) begin
      reg_next.state = STATE_IDLE;
    end
  end
       
    
  always @ (posedge clk) begin  
    reg_current <= reg_next;
	end
endmodule

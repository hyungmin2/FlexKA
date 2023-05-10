
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

    logic [$clog2(OUT_BUFFER_SIZE)-1:0] sub_z1_idx_start;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] sub_c_idx_begin_others;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] sub_z1_idx_limit;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] sub_z0_idx_limit;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] sub_z2_idx_limit;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] sub_c_idx_end;
    
    logic sub_z_ready;
    logic sub_z_ready2;
    logic sub_z_valid;
    logic [FSIZE-1:0] load_sub_z1;
    logic [FSIZE-1:0] load_sub_z0;
    logic [FSIZE-1:0] load_sub_z2;
    logic [FSIZE-1:0] load_sub_c;
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
    logic C_raddr3_first;
    logic C_raddr3_last;
    logic C_raddr3_begin_others;
    logic C_raddr0_exceed_limit;
    logic C_raddr1_exceed_limit;
    logic C_raddr2_exceed_limit;
  } Registers;
    
   Registers reg_current,reg_next;
  
  localparam VALID_IDLE = 0;
  localparam VALID_SUB_Z1_Z0_Z2 = 1;

  localparam STATE_SUB_Z1_Z0_Z2_LOAD = 2;
  localparam STATE_WAIT_SUB_Z1_Z0_Z2 = 3;


  logic reset_ctrl_fifos;
  logic [1-1:0] add_valid;
  logic [1-1:0] add_valid_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_valid_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_valid_fifo_in), .out(add_valid));
  logic add_operand_first;
  logic add_operand_first_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_first_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_first_fifo_in), .out(add_operand_first));
  logic add_operand_z1_zero;
  logic add_operand_z1_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_z1_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_z1_zero_fifo_in), .out(add_operand_z1_zero));
  logic add_operand_z0_zero;
  logic add_operand_z0_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_z0_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_z0_zero_fifo_in), .out(add_operand_z0_zero));
  logic add_operand_z2_zero;
  logic add_operand_z2_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_z2_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_z2_zero_fifo_in), .out(add_operand_z2_zero));
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
    add_operand_z1_zero_fifo_in = 0;
    add_operand_z0_zero_fifo_in = 0;
    add_operand_z2_zero_fifo_in = 0;
    add_operand_end_fifo_in = 0;

    PCC_done = 0;

    Mem_C_inputs_read_valid = 0;

    reset_ctrl_fifos = 0;
            
    //drive C + Z1 - Z0 - Z2
    if(PCC_start) begin
      // Mem_C_inputs_read_valid = 1;

      reg_next.C_raddr0 = stack_pos_C+msize+rsize;      //z1_idx
      reg_next.C_raddr1 = stack_pos_C+msize;            //z0_idx
      reg_next.C_raddr2 = stack_pos_C+msize+(msize<<1);    //z2_idx
      reg_next.C_raddr3 = stack_pos_C+msize;            //C
      
      reg_next.C_raddr3_first = 1;
      reg_next.C_raddr3_last = 0;
      if(rsize == 1) begin
        reg_next.C_raddr3_last = 1;        
      end
      reg_next.C_raddr3_begin_others = 0;
      reg_next.C_raddr0_exceed_limit = 0;
      reg_next.C_raddr1_exceed_limit = 0;
      reg_next.C_raddr2_exceed_limit = 0;

      reg_next.sub_z1_idx_start = stack_pos_C+rsize;

      reg_next.sub_c_idx_begin_others = stack_pos_C_plus_msize_minus_one+msize;

      reg_next.sub_z1_idx_limit = stack_pos_C_plus_msize_minus_one+rsize+localsave_size_A2 + localsave_size_B2;
      reg_next.sub_z0_idx_limit = stack_pos_C_plus_msize_minus_one+(msize<<1);
      reg_next.sub_z2_idx_limit = stack_pos_C_plus_msize_minus_one+rsize;
      
      reg_next.sub_c_idx_end = stack_pos_C_plus_msize_minus_one+rsize;
      
      reg_next.state = STATE_SUB_Z1_Z0_Z2_LOAD;
    end

    if(reg_current.state == STATE_SUB_Z1_Z0_Z2_LOAD) begin      
      Mem_C_inputs_read_valid = 1;
      
      reg_next.C_raddr3 = reg_current.C_raddr3 + 1;
      if(reg_next.C_raddr3 == reg_current.sub_c_idx_end) begin
        reg_next.C_raddr3_last = 1;
      end
      if(reg_current.C_raddr3 == reg_current.sub_c_idx_begin_others) begin
        reg_next.C_raddr3_begin_others = 1;
      end

      add_valid_fifo_in = VALID_SUB_Z1_Z0_Z2;

      // if( reg_current.C_raddr3 >= stack_pos_C + msize) begin
      if( reg_current.C_raddr3_begin_others ) begin
        reg_next.C_raddr0 = reg_current.C_raddr0 + 1;
        reg_next.C_raddr1 = reg_current.C_raddr1 + 1;
        reg_next.C_raddr2 = reg_current.C_raddr2 + 1;
      end
      else begin
        add_operand_z1_zero_fifo_in = 1;        
        add_operand_z0_zero_fifo_in = 1;        
        add_operand_z2_zero_fifo_in = 1;        
      end

      if(reg_current.C_raddr0 == reg_current.sub_z1_idx_limit) begin
        reg_next.C_raddr0_exceed_limit = 1;
      end
      if(reg_current.C_raddr1 == reg_current.sub_z0_idx_limit) begin
        reg_next.C_raddr1_exceed_limit = 1;
      end
      if(reg_current.C_raddr2 == reg_current.sub_z2_idx_limit) begin
        reg_next.C_raddr2_exceed_limit = 1;
      end

      if(reg_current.C_raddr3_first) begin
        reg_next.C_raddr3_first = 0;
        add_operand_first_fifo_in = 1;
      end

      // if(reg_current.C_raddr0 >= reg_current.sub_z1_idx_limit)
      if(reg_current.C_raddr0_exceed_limit)
        add_operand_z1_zero_fifo_in = 1;        
      // if(reg_current.C_raddr1 >= reg_current.sub_z0_idx_limit)
      if(reg_current.C_raddr1_exceed_limit)
        add_operand_z0_zero_fifo_in = 1;
      // if(reg_current.C_raddr2 >= reg_current.sub_z2_idx_limit)
      if(reg_current.C_raddr2_exceed_limit)
        add_operand_z2_zero_fifo_in = 1;
      
      // if(reg_next.C_raddr3 == reg_current.sub_c_idx_end) begin
      if(reg_current.C_raddr3_last) begin
        reg_next.state = STATE_WAIT_SUB_Z1_Z0_Z2;
        add_operand_end_fifo_in = 1;
      end
    end
      
    if(reg_current.state == STATE_WAIT_SUB_Z1_Z0_Z2) begin
    end

   
    reg_next.sub_z_ready = 0;


    reg_next.load_sub_z1 = Mem_C_outputs_rdata0;    
    reg_next.load_sub_z0 = Mem_C_outputs_rdata1;    
    reg_next.load_sub_z2 = Mem_C_outputs_rdata2;    
    reg_next.load_sub_c  = Mem_C_outputs_rdata3;    
      

      if(add_operand_z1_zero) begin
        reg_next.load_sub_z1 = 0;
      end
      if(add_operand_z0_zero) begin
        reg_next.load_sub_z0 = 0;
      end
      if(add_operand_z2_zero) begin
        reg_next.load_sub_z2 = 0;
      end
      
    if(add_valid == VALID_SUB_Z1_Z0_Z2) begin

      // if($time()%2==0) $display("FINAL ADD add_valid at %d",$time()/2) ; 
      reg_next.sub_z_ready = 1;

      if(add_operand_first) begin
        reg_next.sub_carry = 0;
        reg_next.add_carry = 0;
        reg_next.out_data_addr_next = stack_pos_C;        
        reg_next.pop_requested = 0;
      end

      if(add_operand_end) begin
        // reg_next.state = STATE_ADD_Z20_Z1_BEGIN;       

        reg_next.state = STATE_IDLE;
        PCC_done = 1;
        reset_ctrl_fifos = 1;
        reg_next.pop_requested = 1;
        // if($time()%2==0) $display("FINAL ADD requesting state_pop 0 at %d",$time()/2) ; 
      end
    end

    
    reg_next.sub_z_valid = 0;
    
    reg_next.sub_z_res = reg_current.load_sub_c + reg_current.load_sub_z1 - reg_current.load_sub_z0 - reg_current.load_sub_z2;
    reg_next.sub_z_res_carry = reg_current.sub_z_res - reg_current.sub_carry + reg_current.add_carry ;
    

    reg_next.sub_z_ready2 = 0;
    if(reg_current.sub_z_ready) begin
      reg_next.sub_z_ready2 = 1;

      // if($time()%2==0) $display("c+z1-z0-z2 %x %x %x %x = %x at %d"
      //       ,reg_current.load_sub_c,reg_current.load_sub_z1,reg_current.load_sub_z0,reg_current.load_sub_z2            
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

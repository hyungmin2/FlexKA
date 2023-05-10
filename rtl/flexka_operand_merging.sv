`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module flexka_operand_merging #(
        parameter IS_A        = 1
	) (
		input logic	clk,		    		
		input logic rstn,			

    input logic [SSIZE-1:0] msize,
    input logic [SSIZE-1:0] stack_pos,
    input logic [SSIZE-1:0] stack_size,
    input logic [SSIZE-1:0] stack_temp_pos,
  
    input logic OM_start,
    output logic OM_done,
    
    output logic ram_inputs_read_valid,
    output BufferRAMTFsizeInputsR2W1 ram_inputs,

    input logic [FSIZE-1:0] ram_outputs_rdata0,
    input logic [FSIZE-1:0] ram_outputs_rdata1,

    output logic [SSIZE-1:0] localsave_in_size_2
	);

  typedef struct packed {    
    logic [7:0] state;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] add_h_idx_start;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] add_l_idx_start;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] add_h_idx_end;
    logic add_h_idx_end_last;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] add_l_idx_end;
    logic add_l_idx_end_excedeed;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] OM_addr_next;


    logic [FSIZE-1:0] load_L;
    logic [FSIZE-1:0] load_H;
    logic [FSIZE:0] OM_res;
    logic add_carry;
    logic OM_last;


    logic OM_ready;
    logic OM_ready_check_carry;
    logic OM_valid;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] in_addr;


    logic OM_done;


    logic [$clog2(IN_BUFFER_SIZE)-1:0] out_data_addr;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] out_data_addr_next;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] raddr0;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] raddr1;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_size_minus_msize;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_size_minus_msize_plus_one;

    logic [SSIZE-1:0] localsave_in_size_2;

  } Registers;
    
  Registers reg_current,reg_next;
  
  localparam VALID_IDLE = 0;
  localparam VALID_ADD_H_L = 3;
  

  localparam STATE_ADD_H_L_LOAD = 22;
  localparam STATE_WAIT_SUB_Z1_Z0_Z2 = 53;


  logic reset_ctrl_fifos;
  logic [3:0] add_valid;
  logic [3:0] add_valid_fifo_in;
  FifoBuffer #(.DATA_SIZE(4), .CYCLES(BUFFER_READ_LATENCY) )  add_valid_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_valid_fifo_in), .out(add_valid));
  logic add_operand_first;
  logic add_operand_first_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_first_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_first_fifo_in), .out(add_operand_first));
  logic add_operand_zero;
  logic add_operand_zero_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  add_operand_zero_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_zero_fifo_in), .out(add_operand_zero));
  logic add_operand_end;
  logic add_operand_end_fifo_in;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY+1) )  add_operand_end_fifo (.clk(clk), .rstn(!reset_ctrl_fifos), .in(add_operand_end_fifo_in), .out(add_operand_end));

  always_comb begin
    //  if($time()%2==0 && reg_current.state!=0) 
    //       $display("ADD H L A?%d state:%d stack_size:%d m:%d at %d"
    //             ,IS_A,reg_current.state,stack_size,msize                
    //             ,$time()/2) ; 

    reg_next = reg_current;
    
    ram_inputs_read_valid = 0;
    
    ram_inputs.raddr0 = reg_current.raddr0;    
    ram_inputs.raddr1 = reg_current.raddr1;        
    ram_inputs.waddr = reg_current.in_addr;    
    ram_inputs.wdata = 0;
    ram_inputs.wren = 0;
    
    add_valid_fifo_in = VALID_IDLE;
    add_operand_first_fifo_in = 0;
    add_operand_zero_fifo_in = 0;
    add_operand_end_fifo_in = 0;

    OM_done = reg_current.OM_done;
    localsave_in_size_2 = reg_current.localsave_in_size_2;

    reset_ctrl_fifos = 0;
            
    if(OM_start) begin
      reg_next.raddr0 = stack_pos;
      reg_next.raddr1 = stack_pos + msize;

      reg_next.add_l_idx_start = stack_pos;
      reg_next.add_h_idx_start = stack_pos + msize;
      reg_next.add_l_idx_end = stack_pos + msize -1 ;    
      reg_next.add_h_idx_end = stack_pos + stack_size -2;

      reg_next.add_l_idx_end_excedeed = 0;
      reg_next.add_h_idx_end_last = 0;
      if(stack_size == msize+1 ) reg_next.add_h_idx_end_last = 1;

      reg_next.OM_done = 0;

      reg_next.state = STATE_ADD_H_L_LOAD;

      add_operand_first_fifo_in = 1;
      if(stack_size-msize==1) begin
        add_operand_end_fifo_in = 1;
      end

      reg_next.stack_size_minus_msize = stack_size - msize;
      reg_next.stack_size_minus_msize_plus_one = stack_size - msize + 1;

      // if($time()%2==0 ) 
      //     $display("ADD H L A?%d OM_start  stack_size:%d m:%d at %d"
      //           ,IS_A,stack_size,msize                
      //           ,$time()/2) ; 
    end

    if(reg_current.state == STATE_ADD_H_L_LOAD) begin
      ram_inputs_read_valid = 1;

      reg_next.raddr0 = reg_current.raddr0 + 1;
      reg_next.raddr1 = reg_current.raddr1 + 1;

      if(reg_current.raddr0 == reg_current.add_l_idx_end)  reg_next.add_l_idx_end_excedeed = 1;
      if(reg_current.raddr1 == reg_current.add_h_idx_end)  reg_next.add_h_idx_end_last = 1;
       

      add_valid_fifo_in = VALID_ADD_H_L;

      // if(reg_current.raddr0 >= reg_current.add_l_idx_end)
      if(reg_current.add_l_idx_end_excedeed)
        add_operand_zero_fifo_in = 1;
      // if(reg_next.raddr1 == reg_current.add_h_idx_end) begin
      if(reg_current.add_h_idx_end_last) begin
        add_operand_end_fifo_in = 1;
        reg_next.state = STATE_IDLE;
      end

      // if($time()%2==0) $display("ADD H L A?%d  STATE_ADD_H_L_LOAD A_raddr1:%d  A_raddr0:%d  at %d",IS_A,reg_current.raddr1 ,reg_current.raddr0,$time()/2) ; 
    end



    reg_next.OM_ready = 0;
    reg_next.OM_ready_check_carry = 0;
    reg_next.OM_last = 0;
    
    if(add_operand_first) begin
      reg_next.add_carry = 0;
      reg_next.OM_addr_next = stack_temp_pos;
    end

    reg_next.load_L = ram_outputs_rdata0;
    reg_next.load_H = ram_outputs_rdata1;

    if(add_operand_zero) begin
      reg_next.load_L = 0;
    end      
      
    if(add_valid == VALID_ADD_H_L ) begin
      reg_next.OM_ready = 1;

      // if($time()%2==0) $display("ADD H L A?%d VALID_ADD_H_L_AL load_L:%x add_operand_first:%d at %d"
      //       ,IS_A,reg_next.load_L,add_operand_first,$time()/2) ; 
    end


    reg_next.OM_valid = 0;    

    reg_next.OM_res = reg_current.load_L + reg_current.load_H + reg_current.add_carry ;
      
    if(reg_current.OM_ready) begin
      reg_next.OM_valid = 1;
      reg_next.in_addr = reg_current.OM_addr_next;
      reg_next.OM_addr_next = reg_current.OM_addr_next + 1;
      
      reg_next.add_carry =  reg_next.OM_res[FSIZE];
      
      if(add_operand_end )begin
        reg_next.OM_ready_check_carry = 1;        
      end

      // if($time()%2==0) $display("ADD H L A?%d OM_ready OM_res:%x load_L:%x load_H:%x add_carry:%x size_2:%d at %d"
      //       ,IS_A,reg_next.OM_res,reg_current.load_L,reg_current.load_H,reg_current.add_carry,reg_next.localsave_in_size_2,$time()/2) ; 
    end

    if(reg_current.OM_ready_check_carry) begin
      reg_next.OM_done = 1;

      if(reg_current.add_carry) begin
        reg_next.localsave_in_size_2 = reg_current.stack_size_minus_msize_plus_one;
        reg_next.OM_res = 1;      
        reg_next.OM_valid = 1;
        reg_next.in_addr = reg_current.OM_addr_next;
      end
      else begin
        reg_next.localsave_in_size_2 = reg_current.stack_size_minus_msize ;
      end
    end

    if(reg_current.OM_valid) begin      
      ram_inputs.wdata = reg_current.OM_res;
      ram_inputs.wren = 1;

      // if($time()%2==0) $display("ADD H L A?%d OM_valid waddr:%d wdata:%x at %d",IS_A,reg_current.in_addr,reg_current.OM_res,$time()/2) ; 
    end


    if(rstn == 0) begin
      reg_next.state = STATE_IDLE;
    end
  end
       
    
  always @ (posedge clk) begin  
    reg_current <= reg_next;
	end
endmodule

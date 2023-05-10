`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module flexka_base_multiplier (
		input logic	clk,		    		
		input logic rstn,			

    input logic [$clog2(IN_BUFFER_SIZE)-1:0] rsize,
    input logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_size_A,
    input logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_size_B,
    input logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_pos_A,
    input logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_pos_B,
    input logic [$clog2(OUT_BUFFER_SIZE)-1:0] stack_pos_C,
  
    input logic BM_start,
    output logic BM_done,
    
    output logic Mem_A_inputs_read_valid,
    output logic B_ram_inputs_read_valid,
    output BufferRAMTFsizeInputsR2W1 Mem_A_inputs,
    output BufferRAMTFsizeInputsR2W1 B_ram_inputs,
    output BufferRAMTFsizeInputsR4W1 Mem_C_inputs,

    input logic [FSIZE-1:0] Mem_A_outputs_rdata0,
    input logic [FSIZE-1:0] B_ram_outputs_rdata0
	);

  typedef struct packed {    
    logic [$clog2(IN_BUFFER_SIZE)-1:0] A_raddr0;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] B_raddr0;

    logic [$clog2(OUT_BUFFER_SIZE)-1:0] out_addr;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] out_count;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_size_A_minus_1;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] stack_size_B_minus_1;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] res_size_minus_2;

    logic [FSIZE-1:0] load_A;
    logic [FSIZE-1:0] load_B;
    
    logic [FSIZE*2 + $clog2(PRIMITIVE_COUNT) -1:0] accum;

    logic process_mul_end;
    logic process_mul_end_phase;

    logic [PRIMITIVE_COUNT-1:0][FSIZE-1:0] load_L;
    logic [PRIMITIVE_COUNT-1:0][FSIZE-1:0] load_S;    
    
    logic [$clog2(IN_BUFFER_SIZE)-1:0] loading_idx;
    logic loading;
    logic longer_is_A;
    logic loading_A;
    logic loading_B;
    logic write_valid;
    logic final_write_valid;
    
    logic [PRIMITIVE_COUNT-1:0] mul_valids;
    logic [PRIMITIVE_COUNT-1:0] len_short;
  } Registers;
    
  Registers reg_current,reg_next;
  
  logic loaded_A;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY+1) )  loading_A_fifo (.clk(clk), .rstn(1), .in(reg_current.loading_A), .out(loaded_A));
  logic loaded_B;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY+1) )  loading_B_fifo (.clk(clk), .rstn(1), .in(reg_current.loading_B), .out(loaded_B));
  logic [$clog2(IN_BUFFER_SIZE)-1:0] loaded_idx;
  FifoBuffer #(.DATA_SIZE($clog2(IN_BUFFER_SIZE)), .CYCLES(BUFFER_READ_LATENCY+1) )  loaded_idx_fifo (.clk(clk), .rstn(1), .in(reg_current.loading_idx), .out(loaded_idx));

  logic [PRIMITIVE_COUNT-1:0] mul_valids_in,mul_valids;
  FifoBuffer #(.DATA_SIZE(PRIMITIVE_COUNT), .CYCLES(BUFFER_READ_LATENCY+1+1) )  mul_valids_fifo (.clk(clk), .rstn(1), .in(mul_valids_in), .out(mul_valids));
 
  logic [PRIMITIVE_COUNT-1:0][FSIZE*2-1:0] mul_res;
  logic [PRIMITIVE_COUNT-1:0][FSIZE-1:0] mul_A;
  logic [PRIMITIVE_COUNT-1:0][FSIZE-1:0] mul_B;
  logic [PRIMITIVE_COUNT-1:0] mult_valid_in,mult_valid;

  logic [PRIMITIVE_COUNT-2:0][FSIZE*2 + $clog2(PRIMITIVE_COUNT)-1:0] add_res;
  logic [PRIMITIVE_COUNT-2:0][FSIZE*2 + $clog2(PRIMITIVE_COUNT)-1:0] add_A;
  logic [PRIMITIVE_COUNT-2:0][FSIZE*2 + $clog2(PRIMITIVE_COUNT)-1:0] add_B;
  logic [PRIMITIVE_COUNT-2:0] add_valid_in,add_valid;

  logic [FSIZE*2 + $clog2(PRIMITIVE_COUNT)-1:0] add_res_final;
  logic add_valid_final;

  genvar gi,gj,gk,gl;
  generate 
  for (gi = 0; gi <PRIMITIVE_COUNT; gi ++) begin : mult_gen    
    Multiplier mult (
      .CLK(clk),
      .A(mul_A[gi]),
      .B(mul_B[gi]),
      .P(mul_res[gi])
    ); 
    
    FifoBuffer #(.DATA_SIZE(1), .CYCLES(MULTIPLIER_LATENCY) )  mult_valid_fifo (.clk(clk), .rstn(1), .in(mult_valid_in[gi]), .out(mult_valid[gi]));

    assign mult_valid_in[gi] = mul_valids[gi];
    assign mul_A[gi] = mult_valid_in[gi] ? reg_current.load_S[gi] : 0;
    assign mul_B[gi] = mult_valid_in[gi] ? reg_current.load_L[PRIMITIVE_COUNT-1-gi] : 0;

  end

  for (gi = 0; gi <PRIMITIVE_COUNT-1; gi ++) begin : add_gen
    Adder add (
      .CLK(clk),
      .A(add_A[gi]),
      .B(add_B[gi]),
      .P(add_res[gi])
    );  
    
    FifoBuffer #(.DATA_SIZE(1), .CYCLES(ADDER_LATENCY) )  mult_valid_fifo (.clk(clk), .rstn(1), .in(add_valid_in[gi]), .out(add_valid[gi]));    
  end

  for (gi = 0; gi <PRIMITIVE_COUNT/2; gi ++) begin : add_in_gen    
    assign add_A[gi] = mul_res[gi*2+0];
    assign add_B[gi] = mul_res[gi*2+1];
    assign add_valid_in[gi] = mult_valid[gi*2+0] | mult_valid[gi*2+1];
  end
  
  // for (gi = $clog2(PRIMITIVE_COUNT)-2; gi >=0; gi --) begin : add_mid_gen    
  for (gi = 0; gi <$clog2(PRIMITIVE_COUNT)-1; gi ++) begin : add_mid_gen    
    // assign gk = gk + (1 <<(gi+1));
    // assign gk = (( (-1) << (gi+1)  ) % (PRIMITIVE_COUNT));
    // assign gl = (( (-1) << (gi+2)  ) % (PRIMITIVE_COUNT));
    for (gj = 0; gj < (1 <<gi) ; gj ++) begin : add_mid_gen_2          
      assign add_A[(( (32'hFFFFFFFF) << (gi+1)  ) % (PRIMITIVE_COUNT))+gj] = add_res[(( (32'hFFFFFFFF) << (gi+2)  ) % (PRIMITIVE_COUNT)) + gj*2 + 0];
      assign add_B[(( (32'hFFFFFFFF) << (gi+1)  ) % (PRIMITIVE_COUNT))+gj] = add_res[(( (32'hFFFFFFFF) << (gi+2)  ) % (PRIMITIVE_COUNT)) + gj*2 + 1];
      assign add_valid_in[(( (32'hFFFFFFFF) << (gi+1)  ) % (PRIMITIVE_COUNT))+gj] = add_valid[(( (32'hFFFFFFFF) << (gi+2)  ) % (PRIMITIVE_COUNT)) + gj*2 + 0] | add_valid[(( (32'hFFFFFFFF) << (gi+2)  ) % (PRIMITIVE_COUNT)) + gj*2 + 1];
    end
    // assign gl = gl + (1 <<(gi+1));
  end
  assign add_res_final = add_res[PRIMITIVE_COUNT-2];  
  assign add_valid_final = add_valid[PRIMITIVE_COUNT-2];  
  endgenerate
  
  always_comb begin
    // if($time()%2==0 ) 
    //       $display("BM sA:%d sB:%d"
    //             ,stack_size_A,stack_size_B                
    //             ,$time()/2) ; 
    
    reg_next = reg_current;

    Mem_A_inputs_read_valid = 0;
    B_ram_inputs_read_valid = 0;
    
    Mem_A_inputs.raddr0 = 0;
    Mem_A_inputs.raddr1 = 0;
    Mem_A_inputs.waddr = 0;
    Mem_A_inputs.wdata = 0;
    Mem_A_inputs.wren = 0;    

    B_ram_inputs.raddr0 = 0;
    B_ram_inputs.raddr1 = 0;
    B_ram_inputs.waddr = 0;
    B_ram_inputs.wdata = 0;
    B_ram_inputs.wren = 0;

    Mem_C_inputs.raddr0 = 0;
    Mem_C_inputs.raddr1 = 0;

    //short: fixed location
    //long: shift

    //    0 1 2 3  : short: fixed
    // 0        X
    // 1      X
    // 2    X
    // 3  X
    // : long: shift -in from end

    // if(reg_current.longer_is_A) begin
        reg_next.load_A = Mem_A_outputs_rdata0;
        reg_next.load_B = B_ram_outputs_rdata0;
    // end
    // else begin
    //     reg_next.load_L_0 = B_ram_outputs_rdata0;
    //     reg_next.load_S_0 = Mem_A_outputs_rdata0;
    // end

    if(reg_current.longer_is_A) begin
      if(loaded_A)
        reg_next.load_L[PRIMITIVE_COUNT-1] = reg_current.load_A;
      if(loaded_B)
        reg_next.load_S[loaded_idx[$clog2(PRIMITIVE_COUNT)-1:0]] = reg_current.load_B;
    end
    else begin
      if(loaded_B)
        reg_next.load_L[PRIMITIVE_COUNT-1] = reg_current.load_B;
      if(loaded_A)
        reg_next.load_S[loaded_idx[$clog2(PRIMITIVE_COUNT)-1:0]] = reg_current.load_A;
    end
    
    for(int i = 0; i < PRIMITIVE_COUNT-1; i ++) begin
      reg_next.load_L[i] = reg_current.load_L[i+1];
    end

    if(BM_start) begin
      reg_next.loading_idx = 0;
      reg_next.loading_A = 1;
      reg_next.loading_B = 1;
      reg_next.stack_size_A_minus_1 = stack_size_A - 1;
      reg_next.stack_size_B_minus_1 = stack_size_B - 1;
      reg_next.res_size_minus_2 = rsize - 2;
      reg_next.A_raddr0 = stack_pos_A;
      reg_next.B_raddr0 = stack_pos_B;
      reg_next.out_addr = stack_pos_C;
      reg_next.out_count = 0;

      if(stack_size_A >= stack_size_B) begin
        reg_next.longer_is_A = 1;
        reg_next.len_short = stack_size_B;
      end
      else begin
         reg_next.longer_is_A = 0;
        reg_next.len_short = stack_size_A;
      end

      reg_next.mul_valids = 1;

      reg_next.accum = 0;
    end    
    
    Mem_A_inputs.raddr0 = reg_current.A_raddr0;
    B_ram_inputs.raddr0 = reg_current.B_raddr0;
    Mem_A_inputs_read_valid = reg_current.loading_A;
    B_ram_inputs_read_valid = reg_current.loading_B;

    if(reg_current.loading_A || reg_current.loading_B) begin
      reg_next.A_raddr0 = reg_current.A_raddr0 + 1;
      reg_next.B_raddr0 = reg_current.B_raddr0 + 1;
      reg_next.loading_idx = reg_current.loading_idx + 1;

      if(reg_current.loading_idx == reg_current.stack_size_A_minus_1) begin
        reg_next.loading_A = 0;
      end
      if(reg_current.loading_idx == reg_current.stack_size_B_minus_1) begin
        reg_next.loading_B = 0;
      end

    end

    if(reg_current.mul_valids) begin
      if(reg_next.loading_A  && reg_next.loading_B) begin
        reg_next.mul_valids = (reg_current.mul_valids << 1) | 1;
      end
      else if (reg_next.loading_A  || reg_next.loading_B) begin
        //maintain.. 
      end
      else begin
        reg_next.mul_valids = (reg_current.mul_valids << 1);
      end      
      
      for(int i = 0; i < PRIMITIVE_COUNT; i ++) begin
        if(i >= reg_current.len_short) begin
          reg_next.mul_valids[i] = 0;
        end
      end
    end
    mul_valids_in = reg_current.mul_valids;

    reg_next.write_valid = 0;
    reg_next.accum = add_res_final + reg_current.accum[FSIZE*2+$clog2(PRIMITIVE_COUNT)-1:FSIZE];
    if(add_valid_final) begin
      reg_next.write_valid = 1;
    end

    if(BM_start) begin
      reg_next.accum = 0;
    end    
    
    reg_next.final_write_valid = 0;
    Mem_C_inputs.wren = 0;
    Mem_C_inputs.waddr = reg_current.out_addr;
    Mem_C_inputs.wdata = reg_current.accum[FSIZE-1:0];
    if(reg_current.write_valid) begin      
      Mem_C_inputs.wren = 1;

      reg_next.out_addr = reg_current.out_addr + 1;
      reg_next.out_count = reg_current.out_count + 1;
      if(reg_current.out_count == reg_current.res_size_minus_2) begin
        reg_next.final_write_valid = 1;
      end
    end
    BM_done = 0;
    if(reg_current.final_write_valid) begin      
      Mem_C_inputs.wren = 1;
      BM_done = 1;
    end

    // if(mul_valid_m1 == VALID_PRIMITIVE_PHASE || mul_valid_m1 == VALID_PRIMITIVE_PHASE_END) begin      
    //   if($time()%2==0) $display("VALID_PRIMITIVE_PHASE  %x * %x at %d",Mem_A_outputs_rdata0,B_ram_outputs_rdata0,$time()/2) ;       
    // end

    if(rstn == 0) begin
      reg_next.loading_A = 0;
      reg_next.loading_B = 0;
      reg_next.mul_valids = 0;
    end
  end
       
    
  always @ (posedge clk) begin  
    reg_current <= reg_next;
	end
endmodule

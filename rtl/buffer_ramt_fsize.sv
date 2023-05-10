`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;


module BufferRAMTFsize #(
  parameter ID      = 0,
  parameter DEPTH   = 512,
  parameter READ_LATENCY = BUFFER_READ_LATENCY,
  parameter DEPTHAD = $clog2(DEPTH)
) (
  input clk,
  input BufferRAMTFsizeInputs inputs,
  output BufferRAMTFsizeOutputs outputs
);
  localparam WIDTH = FSIZE;

  logic[WIDTH-1:0] memory[0:DEPTH-1];

  logic[WIDTH-1:0] rbuffer[0:READ_LATENCY-1];

  assign outputs.rdata = rbuffer[READ_LATENCY-1];
  
  always @ (posedge clk) begin
    rbuffer[0] <= memory[inputs.raddr];
    
    // if(inputs.wren && inputs.raddr==inputs.waddr ) begin
    //   rbuffer[0] <= inputs.wdata;
    // end

    for(int i = 0; i < READ_LATENCY-1; i ++)  
      rbuffer[i+1] <= rbuffer[i];
    
    if(inputs.wren) begin
      memory[inputs.waddr] = inputs.wdata;
    end
	end  
endmodule



module BufferRAMTFsizeR2W1 #(
  parameter ID      = 0,
  parameter DEPTH   = 512,
  parameter READ_LATENCY = BUFFER_READ_LATENCY,
  parameter DEPTHAD = $clog2(DEPTH)
) (
  input clk,
  input BufferRAMTFsizeInputsR2W1 inputs,
  output logic [FSIZE-1:0] rdata0,
  output logic [FSIZE-1:0] rdata1
);
  BufferRAMTFsizeInputs inputs0;
  BufferRAMTFsizeInputs inputs1;
  BufferRAMTFsizeOutputs outputs0;
  BufferRAMTFsizeOutputs outputs1;

  logic [31:0] waddr_reg;
  logic [FSIZE-1:0] wdata_reg;
  logic wren_reg;
  always @ (posedge clk) begin  
    waddr_reg <= inputs.waddr;
    wdata_reg <= inputs.wdata;
    wren_reg <= inputs.wren;
	end

  assign inputs0.raddr = inputs.raddr0;
  assign inputs0.waddr = waddr_reg;
  assign inputs0.wdata = wdata_reg;
  assign inputs0.wren = wren_reg;

  assign inputs1.raddr = inputs.raddr1;
  assign inputs1.waddr = waddr_reg;
  assign inputs1.wdata = wdata_reg;
  assign inputs1.wren = wren_reg;

  BufferRAMTFsize #(
      .ID(ID),
      .DEPTH(DEPTH),
      .READ_LATENCY(READ_LATENCY),
      .DEPTHAD(DEPTHAD)
  ) ram0 (
    .clk(clk),
    .inputs(inputs0),
    .outputs(outputs0)
  );

  BufferRAMTFsize #(
      .ID(ID),
      .DEPTH(DEPTH),
      .READ_LATENCY(READ_LATENCY),
      .DEPTHAD(DEPTHAD)
  ) ram1 (
    .clk(clk),
    .inputs(inputs1),
    .outputs(outputs1)
  );

  assign rdata0 = outputs0.rdata;
  assign rdata1 = outputs1.rdata;

endmodule

module BufferRAMTFsizeR4W1 #(
  parameter ID      = 0,
  parameter DEPTH   = 512,
  parameter READ_LATENCY = BUFFER_READ_LATENCY,
  parameter DEPTHAD = $clog2(DEPTH)
) (
  input clk,
  input BufferRAMTFsizeInputsR4W1 inputs,
  output logic [FSIZE-1:0] rdata0,
  output logic [FSIZE-1:0] rdata1,
  output logic [FSIZE-1:0] rdata2,
  output logic [FSIZE-1:0] rdata3
);
  BufferRAMTFsizeInputs inputs0;
  BufferRAMTFsizeInputs inputs1;
  BufferRAMTFsizeInputs inputs2;
  BufferRAMTFsizeInputs inputs3;
  BufferRAMTFsizeOutputs outputs0;
  BufferRAMTFsizeOutputs outputs1;
  BufferRAMTFsizeOutputs outputs2;
  BufferRAMTFsizeOutputs outputs3;

  logic [31:0] waddr_reg;
  logic [FSIZE-1:0] wdata_reg;
  logic wren_reg;
  always @ (posedge clk) begin  
    waddr_reg <= inputs.waddr;
    wdata_reg <= inputs.wdata;
    wren_reg <= inputs.wren;
	end


  assign inputs0.raddr = inputs.raddr0;
  assign inputs0.waddr = waddr_reg;
  assign inputs0.wdata = wdata_reg;
  assign inputs0.wren = wren_reg;

  assign inputs1.raddr = inputs.raddr1;
  assign inputs1.waddr = waddr_reg;
  assign inputs1.wdata = wdata_reg;
  assign inputs1.wren = wren_reg;

  assign inputs2.raddr = inputs.raddr2;
  assign inputs2.waddr = waddr_reg;
  assign inputs2.wdata = wdata_reg;
  assign inputs2.wren = wren_reg;

  assign inputs3.raddr = inputs.raddr3;
  assign inputs3.waddr = waddr_reg;
  assign inputs3.wdata = wdata_reg;
  assign inputs3.wren = wren_reg;

  BufferRAMTFsize #(
      .ID(ID),
      .DEPTH(DEPTH),
      .READ_LATENCY(READ_LATENCY),
      .DEPTHAD(DEPTHAD)
  ) ram0 (
    .clk(clk),
    .inputs(inputs0),
    .outputs(outputs0)
  );

  BufferRAMTFsize #(
      .ID(ID),
      .DEPTH(DEPTH),
      .READ_LATENCY(READ_LATENCY),
      .DEPTHAD(DEPTHAD)
  ) ram1 (
    .clk(clk),
    .inputs(inputs1),
    .outputs(outputs1)
  );

  BufferRAMTFsize #(
      .ID(ID),
      .DEPTH(DEPTH),
      .READ_LATENCY(READ_LATENCY),
      .DEPTHAD(DEPTHAD)
  ) ram2 (
    .clk(clk),
    .inputs(inputs2),
    .outputs(outputs2)
  );

  BufferRAMTFsize #(
      .ID(ID),
      .DEPTH(DEPTH),
      .READ_LATENCY(READ_LATENCY),
      .DEPTHAD(DEPTHAD)
  ) ram3 (
    .clk(clk),
    .inputs(inputs3),
    .outputs(outputs3)
  );

  assign rdata0 = outputs0.rdata;
  assign rdata1 = outputs1.rdata;
  assign rdata2 = outputs2.rdata;
  assign rdata3 = outputs3.rdata;

endmodule




module BufferRAMTSsize #(
  parameter ID      = 0,
  parameter DEPTH   = 512,
  parameter READ_LATENCY = BUFFER_READ_LATENCY,
  parameter DEPTHAD = $clog2(DEPTH)
) (
  input clk,
  input BufferRAMTSsizeInputs inputs,
  output BufferRAMTSsizeOutputs outputs
);
  localparam WIDTH = SSIZE;

  logic[WIDTH-1:0] memory[0:DEPTH-1];

  logic[WIDTH-1:0] rbuffer[0:READ_LATENCY-1];

  assign outputs.rdata = rbuffer[READ_LATENCY-1];
  
  always @ (posedge clk) begin
    rbuffer[0] <= memory[inputs.raddr];
    for(int i = 0; i < READ_LATENCY-1; i ++)  
      rbuffer[i+1] <= rbuffer[i];
    
    if(inputs.wren) begin
      memory[inputs.waddr] = inputs.wdata;
    end
	end  
endmodule
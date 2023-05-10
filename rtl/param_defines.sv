`timescale 1 ns / 1 ns

package FLEXKA_PKG;

localparam IN_BUFFER_SIZE = 32'h2800;   // Mem_A, Mem_B
localparam OUT_BUFFER_SIZE = 32'h5000;  // Mem_C
localparam STACK_BUFFER_SIZE = 32;      // Stack Memory

localparam COMMAND_WIDTH = 8;


localparam FSIZE = 64;          // W = 64 bit
localparam PRIMITIVE_COUNT = 32; // N_p  
                                // N_th = PRIMITIVE_COUNT*W 

localparam SSIZE = 16;          // Stack parameter width

localparam BUFFER_READ_LATENCY = 5;
localparam MULTIPLIER_LATENCY = 12;
localparam ADDER_LATENCY = 5;

typedef struct  packed {
  logic valid;
  logic [COMMAND_WIDTH-1:0] command;
  logic [FSIZE-1:0] data0;
  logic [FSIZE-1:0] data1;
} CommandDataPort;

typedef struct  packed {
  logic [FSIZE-1:0] state0;
  logic [FSIZE-1:0] state1;
  logic [FSIZE-1:0] state2;
} StatePort;


typedef struct packed{
  logic [31:0]        raddr;
  logic [31:0]        waddr;
  logic [FSIZE-1:0]   wdata;
  logic               wren;
} BufferRAMTFsizeInputs;


typedef struct packed{
  logic [31:0]        raddr0;
  logic [31:0]        raddr1;
  logic [31:0]        waddr;
  logic [FSIZE-1:0]   wdata;
  logic               wren;
} BufferRAMTFsizeInputsR2W1;


typedef struct packed{
  logic [31:0]        raddr0;
  logic [31:0]        raddr1;
  logic [31:0]        raddr2;
  logic [31:0]        raddr3;
  logic [31:0]        waddr;
  logic [FSIZE-1:0]   wdata;
  logic               wren;
} BufferRAMTFsizeInputsR4W1;

typedef struct packed{
  logic [FSIZE-1:0]   rdata;
} BufferRAMTFsizeOutputs;


typedef struct packed{
  logic [31:0]        raddr;
  logic [31:0]        waddr;
  logic [SSIZE-1:0]   wdata;
  logic               wren;
} BufferRAMTSsizeInputs;

typedef struct packed{
  logic [SSIZE-1:0]   rdata;
} BufferRAMTSsizeOutputs;

localparam COMMAND_RESET = 1;

localparam COMMAND_KARATSUBA_SIZE_A = 2;
localparam COMMAND_KARATSUBA_SIZE_B = 3;
localparam COMMAND_KARATSUBA_DATA_A = 4;
localparam COMMAND_KARATSUBA_DATA_B = 5;
localparam COMMAND_KARATSUBA = 6;
localparam COMMAND_KARATSUBA_OUTADDR = 7;

localparam STATE_IDLE = 0;

endpackage: FLEXKA_PKG


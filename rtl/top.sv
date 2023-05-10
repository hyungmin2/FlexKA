`timescale 1 ns / 1 ns

import FLEXKA_PKG::*;

module flexka_top (
		input logic	clk,		    		
		input logic rstn,			

    input CommandDataPort commanddataport,
    output StatePort stateport
	);


  flexka flexka (
    .clk(clk),
    .rstn(rstn),
    .commanddataport(commanddataport),
    .flexka_state(stateport.state0),
    .out_data_port(stateport.state1),
    .elapsed_cycles_port(stateport.state2)
  );

endmodule

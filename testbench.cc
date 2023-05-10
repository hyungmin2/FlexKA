#include <verilated.h>
#include "Vflexka_top.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "flexka_testbench.h"


#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

vluint64_t main_time = 0;
vluint64_t main_cycle = 0;
double sc_time_stamp() {
    return main_time;  // Note does conversion to real, to match SystemC
}


int main(int argc, char* argv[]) {

  int input_size = 8192;
  int opt;

  while ((opt = getopt(argc, argv, "n:")) != -1) {
      switch (opt) {
      case 'n': input_size = atoi(optarg); break;
      default:
          fprintf(stderr, "Usage: %s [-n input_bit_size]\n",argv[0]);
          exit(EXIT_FAILURE);
      }
  }

  Verilated::debug(0); //0: off, 9: highest
  Verilated::randReset(2);

  Verilated::commandArgs(argc, argv);

  Vflexka_top* top = new Vflexka_top;

#if VM_TRACE
  VerilatedVcdC* tfp = NULL;
  const char* flag = Verilated::commandArgsPlusMatch("trace");
  if (flag && strcmp(flag, "+trace") == 0) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // 99 hierarchy levels
    Verilated::mkdir("logs");
    tfp->open("logs/dump.vcd"); 
    VL_PRINTF("Dumping wave into logs/dump.vcd\n");
  }
#endif
  FlexKATestBench flexka_tb(top);
  flexka_tb.set_input_size(input_size);
  flexka_tb.initialize();

  while (!Verilated::gotFinish()) {
    main_time++; 
    top->clk = !top->clk;
              
    if(main_time % 2 == 0) {        
      main_cycle++;
    }       

    top->eval();

    if(main_time %2 == 1) {
      if( !flexka_tb.step_cycle(main_cycle) ) break;
    }

#if VM_TRACE
    // Dump trace data for this cycle
    if (tfp) tfp->dump(main_time);
#endif
  }
  
  flexka_tb.finish();

  top->final();


#if VM_TRACE
  if (tfp) { tfp->close(); tfp = NULL; }
#endif

  delete top; top = NULL;

  exit(0);
}


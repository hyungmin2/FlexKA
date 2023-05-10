
#include "flexka_testbench.h"
#include "Vflexka_top.h"
#include <iostream>


void FlexKATestBench::pass_n_cycles(int n) {
  for (int i = 0; i < n; i++) {
    host_getstates();
  }
}

void FlexKATestBench::host_getstates() {
  mtx.lock();
  mtx.unlock();
  state_ready = false;
  state_id_req = STATE;
  std::this_thread::yield();

  while(1) {
    mtx.lock();
    if(state_ready) {
      mtx.unlock();
      return;
    }

    mtx.unlock();
    std::this_thread::yield();
  }
}

void FlexKATestBench::host_setcommand(int type, CommandDataPort command)  {
  pass_n_cycles(10);

  mtx.lock();
  command_queue.push(command);
  command_id_queue.push(type);
  mtx.unlock();
}


FlexKATestBench::FlexKATestBench(Vflexka_top* _top) 
  : top(_top)
  {
  
  cdp_zero.valid = 0;
  cdp_zero.command = 0;
  cdp_zero.command_data0 = 0;
  cdp_zero.command_data1 = 0;

  stop_cycle = -1;
}


void FlexKATestBench::initialize() {
  // Initial input values
  top->clk = 0;
  top->rstn = 1;
  
  cdp_zero.ConvertToPort(top->commanddataport);
  
  host_thread = std::thread(&FlexKATestBench::host_function, this);
}

bool FlexKATestBench::step_cycle(vluint64_t cycle) {
  //reset
  top->rstn = 1;
  if(cycle < 20)  top->rstn = 0;

  // get state 
  {
    mtx.lock();
    if(state_id_req == STATE) {
      host_stateport.ConvertFromPort(top->stateport);
    }
    state_ready = true;
    mtx.unlock();
  }

  //set command
  {
    cdp_zero.ConvertToPort(top->commanddataport);
    
    mtx.lock();
    if(!command_id_queue.empty()) {
      int command_id = command_id_queue.front();
      CommandDataPort command = command_queue.front();
      command_id_queue.pop();
      command_queue.pop();

      // std::cout << "received command " << command_id << " " << (int)command.command << " at cycle " << cycle <<std::endl;

      if(command_id == COMMAND) {
        command.ConvertToPort(top->commanddataport);
      }
      else if(command_id == COMMAND_STOP) {
        stop_cycle = cycle + 100; //set stop cycle
        // std::cout << "set  stop cycle at " << stop_cycle << " current cycle " << cycle<< std::endl;
      }
    }

    mtx.unlock();    
  }
 
  if(stop_cycle == cycle)  return false; //stop

  return true;
}

void FlexKATestBench::finish() {
  host_thread.join();  
}


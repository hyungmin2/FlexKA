#ifndef __FLEXKA_TESTBENCH_H__
#define __FLEXKA_TESTBENCH_H__

#include <verilated.h>
#include "Vflexka_top.h"


#include <queue>
#include <map>
#include <vector>
#include <thread>
#include <mutex>



struct CommandDataPort {
  uint8_t valid;
  uint8_t command;
  uint64_t command_data0;
  uint64_t command_data1;

  void ConvertFromPort(const WData* p_packed_val) {
    command_data1 = (p_packed_val[0]) |  ( (uint64_t)p_packed_val[1] << 32);
    command_data0 = (p_packed_val[2]) |  ( (uint64_t)p_packed_val[3] << 32);
    command = p_packed_val[4] & 0xFF;
    valid = (p_packed_val[4] >> 8) & 0x1;
  }

  void ConvertToPort(WData* p_packed_val) {
    p_packed_val[0] = command_data1;
    p_packed_val[1] = command_data1 >> 32;
    p_packed_val[2] = command_data0;
    p_packed_val[3] = command_data0 >> 32;
    p_packed_val[4] = command | (valid<<8);
  }
} ;



struct StatePort {
  uint64_t state0;
  uint64_t state1;
  uint64_t state2;

  void ConvertFromPort(const WData* p_packed_val) {
    state2 = (p_packed_val[0]) |  ( (uint64_t)(p_packed_val[1]) << 32UL);
    state1 = (p_packed_val[2]) |  ( (uint64_t)(p_packed_val[3]) << 32UL);
    state0 = (p_packed_val[4]) |  ( (uint64_t)(p_packed_val[5]) << 32UL);
  }

  void ConvertToPort(WData* p_packed_val) {
    p_packed_val[0] = state2;
    p_packed_val[1] = state2 >> 32;
    p_packed_val[2] = state1;
    p_packed_val[3] = state1 >> 32;
    p_packed_val[4] = state0;
    p_packed_val[5] = state0 >> 32;
  }
} ;




#define COMMAND 0
#define COMMAND_STOP 1

#define STATE 0

class FlexKATestBench {
  private:
    Vflexka_top* top;

    CommandDataPort cdp_zero;
    
    int64_t stop_cycle;

    //fake host program
    std::thread host_thread;
    std::mutex mtx;

    std::queue<CommandDataPort> command_queue;
    std::queue<int>             command_id_queue;
    int                         state_id_req;
    int                         state_ready;
    
    int input_size;

    StatePort      host_stateport;
    
    void host_function();

    void pass_n_cycles(int n);
    void host_getstates();
    void host_setcommand(int type, CommandDataPort command);
                                
    void Control_Karatsuba(
                                  uint64_t  in_size_A,
                                  uint64_t  in_size_B,
                                  uint64_t*  in_A,
                                  uint64_t*  in_B,
                                  uint64_t*  out_C
                                );
      
    void Control_WaitforIdle();

  public:
    FlexKATestBench(Vflexka_top* _top) ;
    void initialize();
    bool step_cycle(vluint64_t cycle) ; //return false when stop
    void finish() ;
    void set_input_size(int size) {input_size = size;}
};



#endif // __FLEXKA_TESTBENCH_H__
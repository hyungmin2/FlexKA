#include "flexka_testbench.h"
#include "gmp_reference.h"

#include <iostream>



#define COMMAND_RESET 1

#define COMMAND_KARATSUBA_SIZE_A 2
#define COMMAND_KARATSUBA_SIZE_B 3
#define COMMAND_KARATSUBA_DATA_A 4
#define COMMAND_KARATSUBA_DATA_B 5
#define COMMAND_KARATSUBA 6
#define COMMAND_KARATSUBA_OUTADDR 7

#define STATE_IDLE 0


extern vluint64_t main_cycle;

void FlexKATestBench::Control_WaitforIdle()  {
  pass_n_cycles(10);

  //Wait until the FlexKA state returns to STATE_IDLE

  while(true) {
    host_getstates();
    if(host_stateport.state0 == STATE_IDLE)  break;
  }
}


void FlexKATestBench::Control_Karatsuba(
                                  uint64_t  in_size_A,
                                  uint64_t  in_size_B,
                                  uint64_t*  in_A,
                                  uint64_t*  in_B,
                                  uint64_t*  out_C                                
) {
  //FlexKA computation

  CommandDataPort command;
  command.valid = 1;
  command.command_data0 = 0;
  command.command_data1 = 0;
    
  //Set input data A & B, in W bit chunks  
  command.command = COMMAND_KARATSUBA_SIZE_A;
  command.command_data0 = in_size_A;
  host_setcommand(COMMAND,command); 

  command.command = COMMAND_KARATSUBA_SIZE_B;
  command.command_data0 = in_size_B;
  host_setcommand(COMMAND,command); 

  for(int i = 0; i < in_size_A; i ++) {
    command.command = COMMAND_KARATSUBA_DATA_A;
    command.command_data0 = in_A[i];
    host_setcommand(COMMAND,command); 
  }

  for(int i = 0; i < in_size_B; i ++) {
    command.command = COMMAND_KARATSUBA_DATA_B;
    command.command_data0 = in_B[i];
    host_setcommand(COMMAND,command); 
  }

  //Invoke FlexKA computation
  command.command = COMMAND_KARATSUBA;
  host_setcommand(COMMAND,command); 

  //Wait until FlexKA finishes
  Control_WaitforIdle();  

  //Retrieve the computation results
  for(int i = 0; i < in_size_A+in_size_B; i ++) {
    command.command = COMMAND_KARATSUBA_OUTADDR;
    command.command_data0 = i;
    host_setcommand(COMMAND,command); 
  
    pass_n_cycles(10);

    out_C[i] = host_stateport.state1;
  }

  host_getstates();
  printf("FlexKA Computation Cycles: %ld\n",host_stateport.state2);
}

void FlexKATestBench::host_function()  {
  srand(13);


  int size_A = input_size / 64;
  int size_B = input_size / 64;

  uint64_t* buf_A = (uint64_t*)malloc(size_A*sizeof(uint64_t));
  uint64_t* buf_B = (uint64_t*)malloc(size_B*sizeof(uint64_t));
  uint64_t* buf_C_FlexKA = (uint64_t*)malloc((size_A+size_B)*sizeof(uint64_t));
  uint64_t* buf_C_ref = (uint64_t*)malloc((size_A+size_B)*sizeof(uint64_t));

  //Generate Random A & B input bits
  for(int i = 0; i < size_A; i ++) {
    buf_A[i] = (((uint64_t)(rand() & 0xFFFF))<<48)| (((uint64_t)(rand() & 0xFFFF))<<32) | (((uint64_t)(rand() & 0xFFFF))<<16) | (rand() & 0xFFFF) ;
  }
  for(int i = 0; i < size_B; i ++) {
    buf_B[i] = (((uint64_t)(rand() & 0xFFFF))<<48)| (((uint64_t)(rand() & 0xFFFF))<<32) | (((uint64_t)(rand() & 0xFFFF))<<16) | (rand() & 0xFFFF) ;
  }
  
  for(int i = 0; i < size_A+size_B; i ++) {
    buf_C_FlexKA[i] = 0;
  }

  //Compute the reference result using GMP
  GMP_Reference::reference(buf_A,buf_B,buf_C_ref,size_A,size_B);

  
  CommandDataPort command;

  //Reset FlexKA
  command.valid = 1;  
  command.command = COMMAND_RESET;
  host_setcommand(COMMAND,command);

  pass_n_cycles(10);

  //Launch FlexKA computation
  Control_Karatsuba(size_A,size_B,
              buf_A,
              buf_B,
              buf_C_FlexKA
              );

  //Result Verification
  int flexka_match = 1;
  for(int i = 0; i < size_A+size_B; i++) {
    if(buf_C_ref[i] != buf_C_FlexKA[i]) {
      printf("FlexKA mismatch i:%d %lx - %lx\n",i,buf_C_ref[i],buf_C_FlexKA[i]);
      flexka_match = 0;
    }
  }
  
  if(flexka_match) printf("FlexKA match\n");
  if(!flexka_match) printf("!!FlexKA mismatch!!!!!\n");

  free(buf_A);
  free(buf_B);
  free(buf_C_FlexKA);
  free(buf_C_ref);  

  host_setcommand(COMMAND_STOP,command);  
}

#include "gmp_reference.h"

#include <iostream>

#include <gmpxx.h>

void GMP_Reference::reference(const uint64_t* in_A, 
                                                const uint64_t* in_B, 
                                                uint64_t* out_C, 
                                                int size_A, 
                                                int size_B
                                                ) {



  mpz_class a = 0;
  for(int i = 0; i < size_A; i ++) {
    uint64_t v = 1UL << 16;
    a = a * v;
    a = a * v;
    a = a * v;
    a = a * v;
    a = a + in_A[size_A-1-i];
  }

  mpz_class b = 0;
  for(int i = 0; i < size_B; i ++) {
    uint64_t v = 1UL << 16;
    b = b * v;
    b = b * v;
    b = b * v;
    b = b * v;
    b = b + in_B[size_B-1-i] ;   
  }

  mpz_class c = a * b;

  for(int i = 0; i < (size_A+size_B)*2; i ++) {
    uint32_t v = 1UL << 16;
    
    mpz_class r = c  & 0xFFFFFFFFUL;
    uint32_t val = r.get_ui();;

    if(i%2 == 0)
      out_C[i/2] = val;
    else
      out_C[i/2] = (((uint64_t)val)<<32) + out_C[i/2];

    c = c / v;
    c = c / v;
  }                              
}

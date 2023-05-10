#ifndef __GMP_REFERENCE_H__
#define __GMP_REFERENCE_H__

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>


class GMP_Reference {
  public:
    static void reference( const uint64_t* in_A,
                             const uint64_t* in_B,
                             uint64_t* out_C,
                             int size_A, 
                             int size_B
                            );
};



#endif // __GMP_REFERENCE_H__
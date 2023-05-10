VERILATOR_FLAGS =
VERILATOR_FLAGS += -cc --exe
VERILATOR_FLAGS += -O2 -x-assign 0
VERILATOR_FLAGS += --trace --trace-structs
VERILATOR_FLAGS += --top-module flexka_top
VERILATOR_FLAGS += --threads 1
VERILATOR_FLAGS += -Wno-CMPCONST
VERILATOR_FLAGS += -Wno-WIDTH
VERILATOR_FLAGS += -LDFLAGS -lgmpxx 
VERILATOR_FLAGS += -LDFLAGS -lgmp
VERILATOR_FLAGS += -CFLAGS -g

TOP_MODULE=flexka_top
output_name=obj_dir/V${TOP_MODULE}

default: output_name

SOURCE_FILES = \
	param_defines.sv \
	buffer_ramt_fsize.sv \
	top.sv \
	flexka.sv \
	flexka_stack.sv \
	flexka_stack_local_node.sv \
	flexka_base_multiplier.sv \
	flexka_operand_merging.sv \
	flexka_partial_product_combination.sv \
	fifo.sv \
	multiplier.sv \
	adder.sv \
	testbench.cc \
	flexka_testbench.cc \
	flexka_testbench_host.cc \
	gmp_reference.cc 

output_name:
	verilator $(VERILATOR_FLAGS) -f input.vc $(SOURCE_FILES)
	$(MAKE) -j -C obj_dir -f Vflexka_top.mk

run:
	@mkdir -p logs
	obj_dir/Vflexka_top -n 8192

run_trace:
	@mkdir -p logs
	obj_dir/Vflexka_top +trace -n 8192

clean:
	-rm -rf obj_dir logs *.log *.dmp *.vpd core
                                                                      
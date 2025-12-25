###############################################################################
# Makefile for cocotb
#
# Author: Tyler Boardman
#
# Date: 12/16/2025
###############################################################################

# test MAKEFILE

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# verilog sources
VERILOG_SRC += $(PWD)/my_design.sv

# vhdl sources
VHDL_SRC +=

#  COCOTB_TOPLEVEL is the name of the toplevel module in your src file
COCOTB_TOPLEVEL = my_design

# COCOTB_TEST_MODULE is the name of the test module in your test file
MODULE ?= test_my_design

# test case can be used to run a specific test inside the to cocotb 'MODULE'
TESTCASE ?=

# e.g.
# cocotb.test()
# async def test_nominal(dut):
#     "...."
# 
# cocotb.test()
# async def test_error(dut):
#     "...."

# make TESTCASE = test_nominal

# include coctb's make rules to take care of the simulator setup
include $(shell python -m cocotb-config --makefiles)/Makefile.sim
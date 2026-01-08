# PCIe to AXI RAM Test

# Tests a simple PCIe endpoint that maps to AXI RAM.
# This test is based on Alex Forencich's pcie_axi_master test.
# 
# portfolio of: Tyler Boardman
# date: 2026-01-01
# github: https://github.com/tylerboardman/cocotb-pcie

import logging
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from cocotb.regression import TestFactory

from cocotbext.pcie.core import RootComplex
from cocotbext.axi import AxiBus, AxiRam

# Import PCIe interface helper
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'verilog-pcie', 'tb'))
from pcie_if import PcieIfDevice, PcieIfRxBus, PcieIfTxBus


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())

        # PCIe Root Complex
        self.rc = RootComplex()

        # PCIe Device (DUT)
        self.dev = PcieIfDevice(
            clk=dut.clk,
            rst=dut.rst,
            rx_req_tlp_bus=PcieIfRxBus.from_prefix(dut, "rx_req_tlp"),
            tx_cpl_tlp_bus=PcieIfTxBus.from_prefix(dut, "tx_cpl_tlp"),
            cfg_max_payload=dut.max_payload_size,

        )

        self.dev.log.setLevel(logging.DEBUG)

        # configure BAR (16MB memory region)
        self.dev.functions[0].configure_bar(0, 16*1024*1024)

        # connect device to root complex
        self.rc.make_port().connect(self.dev)

        # AXI RAM (monitor what the DUT writes to)
        # The AXI signals should be exposed from your top-level module
        self.axi_ram = AxiRam(
            AxiBus.from_prefix(dut, "m_axi"),
            dut.clk,
            dut.rst,
            size=2**16
        )
    # Reset the DUT
    async def cycle_reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)

    # Test PCIe write operations
    async def run_test_write(dut):
        """Test PCIe write operations"""
        tb = TB(dut)

        await tb.cycle_reset()
        await tb.rc.enumerate()

        dev = tb.rc.find_device(tb.dev.functions[0].pcie_id)
        await dev.enable_device()


        dev_bar0 = dev.bar_window[0]
        tb.dut.completer_id.value = int(tb.dev.functions[0].pcie_id)

        # Test various write lengths
        for length in [1, 4, 16, 64, 256, 1024]:
            tb.log.info(f"Testing write length: {length}")
            addr = 0x1000
            test_data = bytearray([x % 256 for x in range(length)])

            # Write via PCIe
            await dev_bar0.write(addr, test_data)

            # Wait for AXI transaction to complete
            await Timer(length * 4 + 200, 'ns')

            # Verify data in AXI RAM
            read_data = tb.axi_ram.read(addr, length)
            assert read_data == test_data, f"Write failed: expected {test_data}, got {read_data}"

        tb.log.info("Write test passed!")

    # Test registration
    if getattr(cocotb, 'top', None) is not None:
        factory = TestFactory(run_test_write)
        factory.generate_tests()

        factory = TestFactory(run_test_read)
        factory.generate_tests()

    test_dir = os.path.dirname(__file__)

    #  this test will be run by cocotb-test
    def test_pcie_axi_ram(request):
        """Test PCIe to AXI RAM"""
        dut = "test_pcie_axi_ram"
        module = os.path.splitext(os.path.basename(__file__))[0]
        toplevel = dut

        verilog_pcie_rtl = os.path.join(test_dir, '..', 'src')

        verilog_sources = [
            os.path.join(test_dir, f"{dut}.v"),
            os.path.join(verilog_pcie_rtl, 'src', 'pcie_axi_ram_top.v'),
            os.path.join(verilog_pcie_rtl, 'pcie_axi_master.v'),
            os.path.join(verilog_pcie_rtl, 'pcie_axi_master_rd.v'),
            os.path.join(verilog_pcie_rtl, 'pcie_axi_master_wr.v'),
            os.path.join(verilog_pcie_rtl, 'src', 'axi_ram.v'),
        ]

        sim_build = os.path.join(test_dir, 'sim_build',
            request.node.name.replace('[', '-').replace(']', ''))

        cocotb_test.simulator.run(
            python_search=[test_dir],
            verilog_sources=verilog_sources,
            toplevel=toplevel,
            module=module,
            sim_build=sim_build,
        )


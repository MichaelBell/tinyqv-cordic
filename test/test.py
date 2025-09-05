# SPDX-FileCopyrightText: © 2025 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV
from testbench import scoreboard

# When submitting your design, change this to the peripheral number
# in peripherals.v.  e.g. if your design is i_user_peri05, set this to 5.
# The peripheral number is not used by the test harness.
PERIPHERAL_NUM = 0

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Interact with your design's registers through this TinyQV class.
    # This will allow the same test to be run when your design is integrated
    # with TinyQV - the implementation of this class will be replaces with a
    # different version that uses Risc-V instructions instead of the SPI test
    # harness interface to read and write the registers.
    tqv = TinyQV(dut, PERIPHERAL_NUM)

    # Reset
    await tqv.reset()

    dut._log.info("Test project behavior")
    
    # Set an input value
    #dut.ui_in.value = 1

    # Wait for two clock cycles to see the output values, because ui_in is synchronized over two clocks,
    # and a further clock is required for the output to propagate.
    await ClockCycles(dut.clk, 3)

    # Test register write and read back
    await tqv.write_word_reg(0, 0x3F000000) #0.5
    assert await tqv.read_byte_reg(0) == 0x00
    assert await tqv.read_hword_reg(0) == 0x0000
    assert await tqv.read_word_reg(0) == 0x3F000000
    await tqv.write_word_reg(1, 0x00000003) #cos
    assert await tqv.read_byte_reg(1) == 0x03
    await ClockCycles(dut.clk, 6)
    assert await tqv.read_byte_reg(3) == 0x01 #done
    assert await tqv.read_byte_reg(2) == 0x00
    assert await tqv.read_hword_reg(2) == 0x9E00
    assert await tqv.read_word_reg(2) == 0x3F609E00

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    #assert dut.uo_out.value == 0x96

    # A second write should work
    #dut.ui_in.value = 0
    await tqv.write_word_reg(0, 0x3F000000) #0.5
    await tqv.write_word_reg(1, 0x00000001) #sin
    assert await tqv.read_byte_reg(1) == 0x01
    await ClockCycles(dut.clk, 6)
    assert await tqv.read_byte_reg(3) == 0x01 #done
    assert await tqv.read_byte_reg(3) == 0x3E
    assert await tqv.read_hword_reg(1) == 0x3EF5
    assert await tqv.read_word_reg(0) == 0x3EF57760

    # Test the interrupt, generated when invalid floating point input
    #dut.ui_in[6].value = 1
    #await ClockCycles(dut.clk, 1)
    #dut.ui_in[6].value = 0
    
    await tqv.write_word_reg(0, 0xFFFFFFFF) #nan
    assert await tqv.read_word_reg(0) == 0xFFFFFFFF

    # Interrupt asserted
    await ClockCycles(dut.clk, 3)
    assert await tqv.is_interrupt_asserted()

    # Interrupt doesn't clear
    await ClockCycles(dut.clk, 10)
    assert await tqv.is_interrupt_asserted()
    
    # Write bottom bit of address 8 high to clear
    await tqv.write_byte_reg(8, 1)
    assert not await tqv.is_interrupt_asserted()

@cocotb.test
async def test_with_scoreboard(dut):
    """
    Test the design with scoreboard
    """
    sb = scoreboard.Scoreboard(
        name="regbus_sb",
        timeout=1000,            # optional
        time_units="us",
        # comparator=lambda dut_txn, model_txn: dut_txn == model_txn,  # default anyway
    )
    sb.start()

    # Example transaction shape (anything hashable/serializable is fine)
    # e.g., tuples: (addr, kind, width, data)
    # Feed expected transactions from your golden model:
    await sb.model_q.put( (0x00, "W", 32, 0x3F000000) )
    await ClockCycles(dut.clk, 12)
    await sb.model_q.put( (0x00, "R",  8, 0x00) )
    await sb.model_q.put( (0x00, "R", 16, 0x9E00) )
    await sb.model_q.put( (0x00, "R", 32, 0x3F609E00) )

    # Meanwhile, your DUT monitor pushes observed transactions:
    # (You would implement a coroutine that watches your bus or TinyQV wrapper
    #  and pushes into sb.dut_q as things happen.)
    await sb.dut_q.put( (0x00, "W", 32, 0x3F000000) )
    await ClockCycles(dut.clk, 12)
    await sb.dut_q.put( (0x00, "R",  8, 0x00) )
    await sb.dut_q.put( (0x00, "R", 16, 0x9E00) )
    await sb.dut_q.put( (0x00, "R", 32, 0x3F609E00) )

    # Signal completion (both sides)
    await sb.model_done()
    await sb.dut_done()

    # Wait for scoreboard to finish (asserts if mismatch/length mismatch)
    await sb.wait()

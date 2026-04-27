import cocotb
from cocotb.triggers import RisingEdge, Timer

CLK_PERIOD_NS = 10
BOOT_ADDR = 0x00000000

async def start_clock(dut):
    """Simple manual clock."""
    dut.clk.value = 0
    while True:
        await Timer(CLK_PERIOD_NS // 2, units="ns")
        dut.clk.value = 1
        await Timer(CLK_PERIOD_NS // 2, units="ns")
        dut.clk.value = 0


async def reset_dut(dut):
    """Apply reset and initialise inputs."""
    dut.rst_n.value = 0

    dut.fetch_addr_in.value = 0
    dut.stall_timeout_val.value = 10
    dut.bus_if_busy.value = 0
    dut.bus_if_done.value = 0
    dut.instr_data_in.value = 0

    # Hold reset low for a couple of cycles
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Release reset
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Small delay just to settle after reset release
    await Timer(1, units="ns")


def check(signal, expected, msg):
    """Small helper for clean assertions."""
    actual = int(signal.value)
    assert actual == expected, f"{msg}: expected {expected:#x}, got {actual:#x}"


@cocotb.test()
async def test_fetch_unit_reset(dut):
    """Checking reset behaviour only."""

    # Start clock
    cocotb.start_soon(start_clock(dut))

    # Drive known values before reset
    dut.rst_n.value = 0
    dut.fetch_addr_in.value = 0
    dut.stall_timeout_val.value = 10
    dut.bus_if_busy.value = 0
    dut.bus_if_done.value = 0
    dut.instr_data_in.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")

    # Check reset-state outputs while reset is asserted
    check(dut.ifu_instr_addr, BOOT_ADDR, "ifu_instr_addr should reset to BOOT_ADDR")
    check(dut.if_ready, 0, "if_ready should reset to 0")
    check(dut.if_stall, 0, "if_stall should reset to 0")
    check(dut.instr_valid, 0, "instr_valid should reset to 0")
    check(dut.if_err, 0, "if_err should reset to 0")
    check(dut.stall_err, 0, "stall_err should reset to 0")

    dut._log.info("Reset test passed.")


@cocotb.test()
async def test_fetch_unit_normal_fetch(dut):
    """Checking normal fetch behaviour."""

    cocotb.start_soon(start_clock(dut))
    await reset_dut(dut)

    fetch_addr = 0x00001000
    instr_word = 0x00500093

    # Start fetch
    dut.fetch_addr_in.value = fetch_addr
    dut.bus_if_busy.value = 0
    dut.bus_if_done.value = 0

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")

    check(dut.ifu_instr_addr, fetch_addr, "Fetch address should be driven")
    check(dut.if_stall, 1, "IFU should stall while fetch is active")
    check(dut.instr_valid, 0, "Instruction should not be valid before completion")

    # Complete fetch
    dut.instr_data_in.value = instr_word
    dut.bus_if_done = 1

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")

    check(dut.instr_data_out, instr_word, "Returned instruction should be captured")
    check(dut.instr_valid, 1, "instr_valid should assert when fetch completes")
    check(dut.if_stall, 0, "if_stall should clear when fetch completes")
    check(dut.if_err, 0, "No error expected")
    check(dut.stall_err, 0, "No stall error expected")

    dut._log.info("Normal fetch test passed.")


@cocotb.test()
async def test_fetch_unit_timeout(dut):
    """Checking timeout behaviour"""

    cocotb.start_soon(start_clock(dut))
    await reset_dut(dut)

    dut.fetch_addr_in.value = 0x00002000
    dut.stall_timeout_val.value = 3
    dut.bus_if_busy.value = 0
    dut.bus_if_done.value = 0

    # Start fetch
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")

    check(dut.if_stall, 1, "IFU should stall after fetch starts")

    # Wait past timeout without completing fetch
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    await Timer(1, units="ns")

    check(dut.stall_err, 1, "stall_err should assert after timeout")
    check(dut.instr_valid, 0, "Instruction should not become valid without bus_if_done")

    dut._log.info("Timeout test passed.")
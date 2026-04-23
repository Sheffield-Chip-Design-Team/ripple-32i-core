import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer




async def reset(dut, cycles: int = 2):
    """Assert active-low reset for *cycles* clock edges."""
    dut.rst_n.value   = 0
    dut.wr_en.value   = 0
    dut.rd_addr.value = 0
    dut.wr_data.value = 0
    dut.rs1_addr.value = 0
    dut.rs2_addr.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1


async def write_reg(dut, addr: int, data: int):
    """Write *data* to register *addr* on the next rising edge."""
    dut.rd_addr.value = addr
    dut.wr_data.value = data
    dut.wr_en.value   = 1
    await RisingEdge(dut.clk)
    dut.wr_en.value   = 0


async def read_reg1(dut, addr: int) -> int:
    """Drive rs1_addr and return rd1_data (combinational – sample after a tiny delay)."""
    dut.rs1_addr.value = addr
    await Timer(1, units="ns")
    return int(dut.rd1_data.value)


async def read_reg2(dut, addr: int) -> int:
    """Drive rs2_addr and return rd2_data (combinational)."""
    dut.rs2_addr.value = addr
    await Timer(1, units="ns")
    return int(dut.rd2_data.value)




@cocotb.test()
async def test_reset_zeroes_all(dut):
    """After reset every readable register must return 0."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    for addr in range(32):
        val = await read_reg1(dut, addr)
        assert val == 0, (
            f"test_reset_zeroes_all FAILED: x{addr} = 0x{val:08X}, expected 0x00000000"
        )
    dut._log.info("test_reset_zeroes_all PASSED – all 32 registers are 0 after reset")




@cocotb.test()
async def test_x0_hardwired_zero(dut):
    """Writes to x0 must be silently ignored; reads always return 0."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    await write_reg(dut, 0, 0xDEADBEEF)   # attempt write to x0

    rd1 = await read_reg1(dut, 0)
    rd2 = await read_reg2(dut, 0)
    assert rd1 == 0, f"test_x0_hardwired_zero FAILED: rd1_data = 0x{rd1:08X}"
    assert rd2 == 0, f"test_x0_hardwired_zero FAILED: rd2_data = 0x{rd2:08X}"
    dut._log.info("test_x0_hardwired_zero PASSED")




@cocotb.test()
async def test_write_enable_gating(dut):
    """A write with wr_en=0 must not change the register."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    # Write a known value to x1
    await write_reg(dut, 1, 0xCAFEBABE)
    val_before = await read_reg1(dut, 1)
    assert val_before == 0xCAFEBABE, "Setup write failed"


    dut.rd_addr.value = 1
    dut.wr_data.value = 0x12345678
    dut.wr_en.value   = 0
    await RisingEdge(dut.clk)

    val_after = await read_reg1(dut, 1)
    assert val_after == 0xCAFEBABE, (
        f"test_write_enable_gating FAILED: x1 = 0x{val_after:08X}, expected 0xCAFEBABE"
    )
    dut._log.info("test_write_enable_gating PASSED")




@cocotb.test()
async def test_write_read_all_regs(dut):
    """Write a unique pattern to x1–x31 and verify each reads back correctly."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    for addr in range(1, 32):
        pattern = (0xA5000000 | (addr << 16) | addr)
        await write_reg(dut, addr, pattern)


    passed = 0
    for addr in range(1, 32):
        expected = (0xA5000000 | (addr << 16) | addr)
        got1 = await read_reg1(dut, addr)
        got2 = await read_reg2(dut, addr)
        assert got1 == expected, (
            f"test_write_read_all_regs FAILED (port 1): x{addr} = 0x{got1:08X}, expected 0x{expected:08X}"
        )
        assert got2 == expected, (
            f"test_write_read_all_regs FAILED (port 2): x{addr} = 0x{got2:08X}, expected 0x{expected:08X}"
        )
        passed += 1
        dut._log.info(f"  x{addr:02d}: 0x{got1:08X} ✓  ({passed}/31)")

    dut._log.info("test_write_read_all_regs PASSED – all 31 registers verified on both read ports")


@cocotb.test()
async def test_dual_port_simultaneous_read(dut):
    """Both read ports must return the correct independent values at the same time."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    await write_reg(dut, 5,  0x11111111)
    await write_reg(dut, 10, 0x22222222)

    dut.rs1_addr.value = 5
    dut.rs2_addr.value = 10
    await Timer(1, units="ns")

    rd1 = int(dut.rd1_data.value)
    rd2 = int(dut.rd2_data.value)

    assert rd1 == 0x11111111, f"test_dual_port_simultaneous_read FAILED: rd1 = 0x{rd1:08X}"
    assert rd2 == 0x22222222, f"test_dual_port_simultaneous_read FAILED: rd2 = 0x{rd2:08X}"
    dut._log.info("test_dual_port_simultaneous_read PASSED")




@cocotb.test()
async def test_back_to_back_writes(dut):
    """The last write in a sequence of back-to-back writes must win."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    for val in [0xAAAAAAAA, 0xBBBBBBBB, 0xCCCCCCCC]:
        await write_reg(dut, 7, val)

    final = await read_reg1(dut, 7)
    assert final == 0xCCCCCCCC, (
        f"test_back_to_back_writes FAILED: x7 = 0x{final:08X}, expected 0xCCCCCCCC"
    )
    dut._log.info("test_back_to_back_writes PASSED")




@cocotb.test()
async def test_reset_clears_written_values(dut):
    """Asserting reset after writes must zero all registers again."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

 
    for addr in range(1, 8):
        await write_reg(dut, addr, 0xFFFFFFFF)


    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    for addr in range(1, 8):
        val = await read_reg1(dut, addr)
        assert val == 0, (
            f"test_reset_clears_written_values FAILED: x{addr} = 0x{val:08X} after reset"
        )

    dut._log.info("test_reset_clears_written_values PASSED")
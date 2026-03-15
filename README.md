# Risc-V 32I Single-Cycle Processor with Wishbone Interface

`rp_rv32i_sc_wb` is a minimal, educational RISC-V processor core implementing the RV32I base integer 
instruction set using a single-cycle microarchitecture. The core exposes a Wishbone B4 compliant master 
interface, providing a simple and well-documented open standard for connecting to memory and peripherals.

This repository contains the RTL source, unit testbenches, and FuseSoC core description for the 
`rp_rv32i_sc_wb` core. It is designed to be instantiated as a component within the broader Ripple-32 
microcontroller SoC, but can equally be used standalone in any Wishbone-compatible design.

## Microarchitecture

The core uses a single-cycle execution model — every instruction is decoded, and executed 
within a single clock cycle - The There is no pipelining, branch prediction, or out-of-order execution. 
This makes the microarchitecture straightforward to reason about, simulate, and verify, at the cost 
of maximum operating frequency.

The datapath is composed of the following units:

| Module            | Description                                               |
|-------------------|-----------------------------------------------------------|
| `opcode_decoder`  | Decodes the 32-bit instruction word into control fields   |
| `control_unit`    | Generates datapath control signals from decoded opcode    |
| `reg_file`        | 32 x 32-bit general purpose register file                 |
| `alu`             | Arithmetic and logic unit supporting all RV32I operations |
| `wb_m_bus_intf`   | Wishbone B4 master interface for memory and I/O access    |

## Interface

The core communicates with memory and peripherals exclusively through its Wishbone master port. 
Instruction fetch and data access are both performed over this interface, following the classic 
von Neumann model with a shared address space.

## Repository Structure
```
hw/
├── rtl/                  # Synthesisable RTL source
│   ├── rp_rv32i_sc_wb.v  # Top-level core
│   ├── ...
└── tb/                   # Unit testbenches (cocotb)
    └── ...
```

## Verification

Unit-level verification is performed using [cocotb](https://www.cocotb.org/).Optionally, FuseSoC may be used to 
manage fileset assembly and simulation targets. Each sub-module has an independent testbench allowing 
targeted verification of individual datapath components.

```bash
# Run the opcode decoder testbench
coral sim --exe verilator --dut opcode_decoder --waves -v

```

## Dependencies
- [FuseSoC](https://fusesoc.readthedocs.io/) — core and fileset management
- [cocotb](https://www.cocotb.org/) — Python-based hardware verification
- [Icarus Verilog](http://iverilog.icarus.com/) or [Verilator](https://www.veripool.org/verilator/) — simulation backend

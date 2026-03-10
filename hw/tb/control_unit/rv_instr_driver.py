import cocotb
from random import randint
from cocotb.triggers import Timer
from cocotb import log
from uuid import uuid4
# RV32I instruction generator/driver for cocotb

def _pick(seq):
  return seq[randint(0, len(seq) - 1)]

def _r_type(funct7, rs2, rs1, funct3, rd, opcode=0b0110011):
  return (
    ((funct7 & 0x7F) << 25)
    | ((rs2 & 0x1F) << 20)
    | ((rs1 & 0x1F) << 15)
    | ((funct3 & 0x7) << 12)
    | ((rd & 0x1F) << 7)
    | (opcode & 0x7F)
  )

def _i_type(imm12, rs1, funct3, rd, opcode):
  return (
    ((imm12 & 0xFFF) << 20)
    | ((rs1 & 0x1F) << 15)
    | ((funct3 & 0x7) << 12)
    | ((rd & 0x1F) << 7)
    | (opcode & 0x7F)
  )

def _s_type(imm12, rs2, rs1, funct3, opcode=0b0100011):
  return (
    (((imm12 >> 5) & 0x7F) << 25)
    | ((rs2 & 0x1F) << 20)
    | ((rs1 & 0x1F) << 15)
    | ((funct3 & 0x7) << 12)
    | ((imm12 & 0x1F) << 7)
    | (opcode & 0x7F)
  )


def _b_type(imm13, rs2, rs1, funct3, opcode=0b1100011):
  return (
    (((imm13 >> 12) & 0x1) << 31)
    | (((imm13 >> 5) & 0x3F) << 25)
    | ((rs2 & 0x1F) << 20)
    | ((rs1 & 0x1F) << 15)
    | ((funct3 & 0x7) << 12)
    | (((imm13 >> 1) & 0xF) << 8)
    | (((imm13 >> 11) & 0x1) << 7)
    | (opcode & 0x7F)
  )


def _u_type(imm20, rd, opcode):
  return (((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F))


def _j_type(imm21, rd, opcode=0b1101111):
  return (
    (((imm21 >> 20) & 0x1) << 31)
    | (((imm21 >> 1) & 0x3FF) << 21)
    | (((imm21 >> 11) & 0x1) << 20)
    | (((imm21 >> 12) & 0xFF) << 12)
    | ((rd & 0x1F) << 7)
    | (opcode & 0x7F)
  )


def random_rv32i_instruction():
  rd = randint(0, 31)
  rs1 = randint(0, 31)
  rs2 = randint(0, 31)
  imm12 = randint(0, 0xFFF)
  imm13 = randint(0, 0x1FFF) & ~0x1  # branch offset aligned
  imm21 = randint(0, 0x1FFFFF) & ~0x1  # jump offset aligned
  imm20 = randint(0, 0xFFFFF)

  gen = _pick(
    [
      lambda: ("ADD", _r_type(0b0000000, rs2, rs1, 0b000, rd)),
      lambda: ("SUB", _r_type(0b0100000, rs2, rs1, 0b000, rd)),
      lambda: ("AND", _r_type(0b0000000, rs2, rs1, 0b111, rd)),
      lambda: ("OR", _r_type(0b0000000, rs2, rs1, 0b110, rd)),
      lambda: ("XOR", _r_type(0b0000000, rs2, rs1, 0b100, rd)),
      lambda: ("ADDI", _i_type(imm12, rs1, 0b000, rd, 0b0010011)),
      lambda: ("ANDI", _i_type(imm12, rs1, 0b111, rd, 0b0010011)),
      lambda: ("ORI", _i_type(imm12, rs1, 0b110, rd, 0b0010011)),
      lambda: ("LW", _i_type(imm12, rs1, 0b010, rd, 0b0000011)),
      lambda: ("SW", _s_type(imm12, rs2, rs1, 0b010)),
      lambda: ("BEQ", _b_type(imm13, rs2, rs1, 0b000)),
      lambda: ("BNE", _b_type(imm13, rs2, rs1, 0b001)),
      lambda: ("LUI", _u_type(imm20, rd, 0b0110111)),
      lambda: ("AUIPC", _u_type(imm20, rd, 0b0010111)),
      lambda: ("JAL", _j_type(imm21, rd)),
      lambda: ("JALR", _i_type(imm12, rs1, 0b000, rd, 0b1100111)),
    ]
  )
  return gen()

class RVInstructionDriver:
  """Driver for randomized RV32I instruction stimulus."""

  def __init__(self, instr_signal, valid_signal=None, delay_ns=5):
    self.instr_signal = instr_signal
    self.valid_signal = valid_signal
    self.delay_ns = delay_ns
    self.component_id = f"rv_instr_driver"
    self.log = cocotb.log.getChild(f"{self.component_id}")

  async def send_random(self, count=100):
    for _ in range(count):
      name, instr = random_rv32i_instruction()
      self.log.debug("Sending random instruction: %s (0x%08x)", name, instr)

      # logging the instruction fields for debugging
      opcode = instr & 0x7F

      if opcode == 0x33:  # R-type
        rd = (instr >> 7) & 0x1F
        funct3 = (instr >> 12) & 0x7
        rs1 = (instr >> 15) & 0x1F
        rs2 = (instr >> 20) & 0x1F
        funct7 = (instr >> 25) & 0x7F
        self.log.debug(
          "0x%02x (%s) R-type: rd=0x%02x rs1=0x%02x rs2=0x%02x funct3=0x%x funct7=0x%02x",
          opcode, name, rd, rs1, rs2, funct3, funct7
        )

      elif opcode in (0x13, 0x03, 0x67):  # I-type (ALU-imm, loads, JALR)
        rd = (instr >> 7) & 0x1F
        funct3 = (instr >> 12) & 0x7
        rs1 = (instr >> 15) & 0x1F
        imm12 = (instr >> 20) & 0xFFF
        self.log.debug(
          "0x%02x (%s) I-type: rd=0x%02x rs1=0x%02x funct3=0x%02x imm12=0x%03x",
          opcode, name, rd, rs1, funct3, imm12
        )

      elif opcode == 0x23:  # S-type (stores)
        imm11_5 = (instr >> 25) & 0x7F
        rs2 = (instr >> 20) & 0x1F
        rs1 = (instr >> 15) & 0x1F
        funct3 = (instr >> 12) & 0x7
        imm4_0 = (instr >> 7) & 0x1F
        imm12 = (imm11_5 << 5) | imm4_0
        self.log.debug(
          "0x%02x (%s) S-type: rs1=0x%02x rs2=0x%02x funct3=0x%x imm12=0x%03x",
          opcode, name, rs1, rs2, funct3, imm12
        )

      elif opcode == 0x63:  # B-type (branches)
        imm12 = (instr >> 31) & 0x1
        imm10_5 = (instr >> 25) & 0x3F
        rs2 = (instr >> 20) & 0x1F
        rs1 = (instr >> 15) & 0x1F
        funct3 = (instr >> 12) & 0x7
        imm4_1 = (instr >> 8) & 0xF
        imm11 = (instr >> 7) & 0x1
        imm13 = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1)
        self.log.debug(
          "0x%02x (%s) B-type: rs1=0x%02x rs2=0x%02x funct3=0x%x imm13=0x%04x",
          opcode, name, rs1, rs2, funct3, imm13
        )

      elif opcode in (0x37, 0x17):  # U-type (LUI/AUIPC)
        rd = (instr >> 7) & 0x1F
        imm20 = (instr >> 12) & 0xFFFFF
        self.log.debug("0x%02x (%s) U-type: rd=0x%02x imm20=0x%05x", opcode, name, rd, imm20)

      elif opcode == 0x6F:  # J-type (JAL)
        rd = (instr >> 7) & 0x1F
        imm20 = (instr >> 31) & 0x1
        imm10_1 = (instr >> 21) & 0x3FF
        imm11 = (instr >> 20) & 0x1
        imm19_12 = (instr >> 12) & 0xFF
        imm21 = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1)
        self.log.debug("0x%02x (%s) J-type: rd=0x%02x imm21=0x%05x", opcode, name, rd, imm21)

      self.instr_signal.value = instr

      if self.valid_signal is not None:
        self.valid_signal.value = 1
      await Timer(self.delay_ns, unit="ns")
    if self.valid_signal is not None:
      self.valid_signal.value = 0


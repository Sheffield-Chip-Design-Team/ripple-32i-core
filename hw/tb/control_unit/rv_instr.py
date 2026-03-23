# RV32I instruction generator/driver for cocotb

import cocotb
from random import randint
from cocotb.triggers import Timer
from cocotb import log

# Instrtuction Types definitions 

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






# TODO - add constraints to this randomization
def random_rv32i_instruction():
  
  rd  = randint(0, 31)
  rs1 = randint(0, 31)
  rs2 = randint(0, 31)
  
  imm12 = randint(0, 0xFFF)
  imm13 = randint(0, 0x1FFF)   & ~0x1    # branch offset aligned
  imm21 = randint(0, 0x1FFFFF) & ~0x1    # jump offset aligned
  imm20 = randint(0, 0xFFFFF)
  
  shamt = randint(0, 31)
 
  # RPL-7 - RV instruction reference 
  gen = _pick(
    [
      # R type                  funct7     rs2  rs1  funct3 rd
      lambda: ("ADD",   _r_type(0b0100000, rs2, rs1, 0b000, rd)),
      lambda: ("XOR",   _r_type(0b0000000, rs2, rs1, 0b100, rd)),
      lambda: ("OR",    _r_type(0b0000000, rs2, rs1, 0b110, rd)),
      lambda: ("AND",   _r_type(0b0000000, rs2, rs1, 0b111, rd)),
      lambda: ("SLL",   _r_type(0b0000000, rs2, rs1, 0b001, rd)),
      lambda: ("SRL",   _r_type(0b0000000, rs2, rs1, 0b101, rd)),
      lambda: ("SRA",   _r_type(0b0100000, rs2, rs1, 0b101, rd)),
      lambda: ("SLT",   _r_type(0b0000000, rs2, rs1, 0b010, rd)),
      lambda: ("SLTU",  _r_type(0b0000000, rs2, rs1, 0b011, rd)),

      # I type                  imm12                     rs1  funct3 rd   opcode
      lambda: ("ADDI",  _i_type(imm12,                    rs1, 0b000, rd, 0b0010011)),
      lambda: ("XORI",  _i_type(imm12,                    rs1, 0b100, rd, 0b0010011)),
      lambda: ("ORI",   _i_type(imm12,                    rs1, 0b110, rd, 0b0010011)),
      lambda: ("ANDI",  _i_type(imm12,                    rs1, 0b111, rd, 0b0010011)),
      lambda: ("SLLI",  _i_type((0b0000000 << 5) | shamt, rs1, 0b001, rd, 0b0010011)),
      lambda: ("SLTIU", _i_type(imm12,                    rs1, 0b011, rd, 0b0010011)),
      lambda: ("SRLI",  _i_type((0b0000000 << 5) | shamt, rs1, 0b101, rd, 0b0010011)),
      lambda: ("SRAI",  _i_type((0b0100000 << 5) | shamt, rs1, 0b101, rd, 0b0010011)),
      lambda: ("SLTI",  _i_type(imm12,                    rs1, 0b010, rd, 0b0010011)),
      
      # Load instructions
      lambda: ("LB",    _i_type(imm12,                    rs1, 0b000, rd, 0b0000011)),
      lambda: ("LH",    _i_type(imm12,                    rs1, 0b001, rd, 0b0000011)),
      lambda: ("LW",    _i_type(imm12,                    rs1, 0b010, rd, 0b0000011)),
      lambda: ("LBU",   _i_type(imm12,                    rs1, 0b100, rd, 0b0000011)),
      lambda: ("LHU",   _i_type(imm12,                    rs1, 0b101, rd, 0b0000011)),

      # S type                 imm12  rs2  rs1  funct3 
      lambda: ("SB",    _s_type(imm12, rs2, rs1, 0b000)),
      lambda: ("SH",    _s_type(imm12, rs2, rs1, 0b001)),
      lambda: ("SW",    _s_type(imm12, rs2, rs1, 0b010)),

      # B type                 imm13  rs2  rs1  funct3
      lambda: ("BEQ",   _b_type(imm13, rs2, rs1, 0b000)),
      lambda: ("BNE",   _b_type(imm13, rs2, rs1, 0b001)),
      lambda: ("BLT",   _b_type(imm13, rs2, rs1, 0b100)),
      lambda: ("BGE",   _b_type(imm13, rs2, rs1, 0b101)),
      lambda: ("BLTU",  _b_type(imm13, rs2, rs1, 0b110)),
      lambda: ("BGEU",  _b_type(imm13, rs2, rs1, 0b111)),

      # J type                  imm21  rd  
      lambda: ("JAL",    _j_type(imm21, rd)),
    
      # I type (JALR)           imm12  rs1   funct3 rd  opcode
      lambda: ("JALR",   _i_type(imm12, rs1, 0b000, rd, 0b1100111)),

      # U type                   imm20  rd   opcode
      lambda: ("LUI",    _u_type(imm20, rd, 0b0110111)),
      lambda: ("AUIPC",  _u_type(imm20, rd, 0b0010111)),

      # SYSTEM                   imm12         opcode
      lambda: ("ECALL",  _i_type(0,    0, 0,0, 0b1110011)),
      lambda: ("EBREAK", _i_type(1,    0, 0,0, 0b1110011)),
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
      self.log.info("Sending random instruction: %s (0x%08x)", name, instr)

      # logging the instruction fields for debugging
      opcode = instr & 0x7F

      if not hasattr(self, "_opcode_loggers"):
        def _log_r_type(name, instr, opcode):
          rd = (instr >> 7) & 0x1F
          funct3 = (instr >> 12) & 0x7
          rs1 = (instr >> 15) & 0x1F
          rs2 = (instr >> 20) & 0x1F
          funct7 = (instr >> 25) & 0x7F
          self.log.info(
        "0x%02x (%s) R-type: rd=0x%02x rs1=0x%02x rs2=0x%02x funct3=0x%x funct7=0x%02x",
        opcode, name, rd, rs1, rs2, funct3, funct7
          )

        def _log_i_type(name, instr, opcode):
          rd = (instr >> 7) & 0x1F
          funct3 = (instr >> 12) & 0x7
          rs1 = (instr >> 15) & 0x1F
          imm12 = (instr >> 20) & 0xFFF
          self.log.info(
        "0x%02x (%s) I-type: rd=0x%02x rs1=0x%02x funct3=0x%x imm12=0x%03x",
        opcode, name, rd, rs1, funct3, imm12
          )

        def _log_s_type(name, instr, opcode):
          imm11_5 = (instr >> 25) & 0x7F
          rs2 = (instr >> 20) & 0x1F
          rs1 = (instr >> 15) & 0x1F
          funct3 = (instr >> 12) & 0x7
          imm4_0 = (instr >> 7) & 0x1F
          imm12 = (imm11_5 << 5) | imm4_0
          self.log.info(
        "0x%02x (%s) S-type: rs1=0x%02x rs2=0x%02x funct3=0x%x imm12=0x%03x",
        opcode, name, rs1, rs2, funct3, imm12
          )

        def _log_b_type(name, instr, opcode):
          imm12 = (instr >> 31) & 0x1
          imm10_5 = (instr >> 25) & 0x3F
          rs2 = (instr >> 20) & 0x1F
          rs1 = (instr >> 15) & 0x1F
          funct3 = (instr >> 12) & 0x7
          imm4_1 = (instr >> 8) & 0xF
          imm11 = (instr >> 7) & 0x1
          imm13 = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1)
          self.log.info(
        "0x%02x (%s) B-type: rs1=0x%02x rs2=0x%02x funct3=0x%x imm13=0x%04x",
        opcode, name, rs1, rs2, funct3, imm13
          )

        def _log_u_type(name, instr, opcode):
          rd = (instr >> 7) & 0x1F
          imm20 = (instr >> 12) & 0xFFFFF
          self.log.info("0x%02x (%s) U-type: rd=0x%02x imm20=0x%05x", opcode, name, rd, imm20)

        def _log_j_type(name, instr, opcode):
          rd = (instr >> 7) & 0x1F
          imm20 = (instr >> 31) & 0x1
          imm10_1 = (instr >> 21) & 0x3FF
          imm11 = (instr >> 20) & 0x1
          imm19_12 = (instr >> 12) & 0xFF
          imm21 = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1)
          self.log.info("0x%02x (%s) J-type: rd=0x%02x imm21=0x%05x", opcode, name, rd, imm21)

        def _log_system_type(name, instr, opcode):
          imm12 = (instr >> 20) & 0xFFF
          self.log.info("0x%02x (%s) SYSTEM: imm12=0x%03x", opcode, name, imm12)

        def _log_unknown(name, instr, opcode):
          self.log.info("0x%02x (%s) Unknown type: instr=0x%08x", opcode, name, instr)

        self._opcode_loggers = {
          0x33: _log_r_type,
          0x13: _log_i_type,
          0x03: _log_i_type,
          0x67: _log_i_type,
          0x23: _log_s_type,
          0x63: _log_b_type,
          0x37: _log_u_type,
          0x17: _log_u_type,
          0x6F: _log_j_type,
          0x73: _log_system_type,
        }
        self._default_opcode_logger = _log_unknown

      self._opcode_loggers.get(opcode, self._default_opcode_logger)(name, instr, opcode)

      self.instr_signal.value = instr

      await Timer(self.delay_ns, unit="ns")
    


    


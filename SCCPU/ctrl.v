// `include "ctrl_encode_def.v"


module ctrl(Op, Funct, Zero, 
            RegWrite, MemWrite,
            EXTOp, ALUOp, NPCOp, 
            ALUSrc, GPRSel, WDSel
            );
            
   input  [5:0] Op;       // opcode
   input  [5:0] Funct;    // funct
   input        Zero;
   
   output       RegWrite; // control signal for register write
   output       MemWrite; // control signal for memory write
   output       EXTOp;    // control signal to signed extension
   output [2:0] ALUOp;    // ALU opertion
   output [1:0] NPCOp;    // next pc operation
   output       ALUSrc;   // ALU source for A

  output GPRSel;   // general purpose register selection
  output WDSel;    // (register) write data selection
   
  // r format, 若执行的是该条指令则对应的wire信号为1
   wire rtype  = ~|Op;
   wire i_add  = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]&~Funct[1]&~Funct[0]; // add
   wire i_sub  = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]& Funct[1]&~Funct[0]; // sub
   wire i_and  = rtype& Funct[5]&~Funct[4]&~Funct[3]& Funct[2]&~Funct[1]&~Funct[0]; // and
   wire i_or   = rtype& Funct[5]&~Funct[4]&~Funct[3]& Funct[2]&~Funct[1]& Funct[0]; // or
   wire i_slt  = rtype& Funct[5]&~Funct[4]& Funct[3]&~Funct[2]& Funct[1]&~Funct[0]; // slt
   wire i_sltu = rtype& Funct[5]&~Funct[4]& Funct[3]&~Funct[2]& Funct[1]& Funct[0]; // sltu
   wire i_addu = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]&~Funct[1]& Funct[0]; // addu
   wire i_subu = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]& Funct[1]& Funct[0]; // subu

   // modified begin: 
   wire i_sll   = rtype&~Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]&~Funct[1]&~Funct[0]; // sll funct:000000
   wire i_nor   = rtype& Funct[5]&~Funct[4]&~Funct[3]& Funct[2]& Funct[1]&Funct[0]; // nor funct:100111
   wire i_srl   = rtype&~Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]& Funct[1]&~Funct[0]; // nor funct:000010
   wire i_sllv  = rtype&~Funct[5]&~Funct[4]&~Funct[3]& Funct[2]&~Funct[1]&~Funct[0]; // sllv funct:000100
   wire i_slrv  = rtype&~Funct[5]&~Funct[4]&~Funct[3]& Funct[2]& Funct[1]&~Funct[0]; // slrv funct:000110
   wire i_jr    = rtype&~Funct[5]&~Funct[4]& Funct[3]&~Funct[2]&~Funct[1]&~Funct[0]; // jr funct:001000
   wire i_jalr  = rtype&~Funct[5]&~Funct[4]& Funct[3]&~Funct[2]&~Funct[1]& Funct[0]; // slrv funct:001001
   // modified end

  // i format
   wire i_addi = ~Op[5]&~Op[4]& Op[3]&~Op[2]&~Op[1]&~Op[0]; // addi
   wire i_ori  = ~Op[5]&~Op[4]& Op[3]& Op[2]&~Op[1]& Op[0]; // ori
   wire i_lw   =  Op[5]&~Op[4]&~Op[3]&~Op[2]& Op[1]& Op[0]; // lw
   wire i_sw   =  Op[5]&~Op[4]& Op[3]&~Op[2]& Op[1]& Op[0]; // sw
   wire i_beq  = ~Op[5]&~Op[4]&~Op[3]& Op[2]&~Op[1]&~Op[0]; // beq

   // modified begin: 
   wire i_lui   = ~Op[5]&~Op[4]& Op[3]& Op[2]& Op[1]& Op[0]; // lui op: 001111 寄存器加载高位
   wire i_slti  = ~Op[5]&~Op[4]& Op[3]&~Op[2]& Op[1]&~Op[0]; // slti op: 001010 小于立即数置1
   wire i_bne   = ~Op[5]&~Op[4]&~Op[3]& Op[2]&~Op[1]& Op[0]; // bne op: 000101 不等时分支
   wire i_andi  = ~Op[5]&~Op[4]& Op[3]& Op[2]&~Op[1]&~Op[0]; // slti op: 001100 立即数与
   // modified end

  // j format
   wire i_j    = ~Op[5]&~Op[4]&~Op[3]&~Op[2]& Op[1]&~Op[0];  // j

  // generate control signals
  assign RegWrite   = rtype | i_lw | i_addi | i_ori | i_lui | i_slti | i_andi; // register write  
  
  assign MemWrite   = i_sw;                           // memory write
  assign ALUSrc     = i_lw | i_sw | i_addi | i_ori | i_lui | i_slti | i_andi;   // ALU B is from instruction immediate
  assign EXTOp      = i_addi | i_lw | i_sw | i_slti;           // signed extension, 0对于零扩展, 1对应符号扩展

  // 目的寄存器选择
  // GPRSel_RD   1'b0
  // GPRSel_RT   1'b1
  assign GPRSel = i_lw | i_addi | i_ori | i_lui | i_slti | i_andi;
  
  // 写入数据选择
  // WDSel_FromALU 2'b00
  // WDSel_FromMEM 2'b01
  // WDSel_FromPC  2'b10 
  // WDSel[1]   WDSel[0]  i_lw  i_lui i_slti
  //    0          0        0     0      1
  //    0          0        0     1      0
  //    0          1        1     0      0
  assign WDSel[0] = i_w;
  // assign WDSel[1] = i_lui;

  // PC来源选择 
  // NPC_PLUS4   2'b00
  // NPC_BRANCH  2'b01
  // NPC_JUMP    2'b10
  assign NPCOp[0] = (i_beq & Zero) | (i_bne & ~Zero);
  assign NPCOp[1] = i_j;
  
  // ALU_NOP   3'b000
  // ALU_ADD   3'b001
  // ALU_SUB   3'b010
  // ALU_AND   3'b011
  // ALU_OR    3'b100
  // ALU_SLT   3'b101
  // ALU_SLTU  3'b110
  assign ALUOp[0] = i_add | i_lw | i_sw | i_addi | i_and | i_slt | i_addu;
  assign ALUOp[1] = i_sub | i_beq | i_and | i_sltu | i_subu;
  assign ALUOp[2] = i_or | i_ori | i_slt | i_sltu;

endmodule

// MBT 1/31/2014
//
// Dissembler for the Vanilla ISA
// This file is intended to be tick-included
// into the main test bench.

// It will not work in timing simulation,
// as it reaches into the verilog hierarchy.
//
// If you change the way that you instantiate
// the core, you will have to update the variable
// ROOT.
//
//
// If you add an instruction, you will
// have to augment the casez statement.

`define ROOT dut.core1

`ifdef DISASSEMBLE
     always @(negedge clk)
       begin
          if (reset &&  `ROOT.state_r != IDLE) // low true
            begin
               $write("{%8.8x} %c PC=%3.3x INSTR=%2.2x PC_wen=%1.1x bubble=%1.1x flush=%1.1x fwd_a=%1.1x fwd_b=%1.1x fwd_c=%1.1x IDLE_WAIT=%1.1x "
                      , cycle_counter_r
                      , `ROOT.PC_wen
                      ? " "
                      : (`ROOT.net_PC_write_cmd_IDLE
                         ? "n"
                         : (`ROOT.stall
                            ? "s"
                            : "?"
                            )
                         )
                      , `ROOT.PC_r
                      , `ROOT.instruction.opcode
					  , `ROOT.PC_wen
					  , `ROOT.bubble
					  , `ROOT.flush
					  , `ROOT.fwd_a
					  , `ROOT.fwd_b
					  , `ROOT.fwd_c
					  , `ROOT.IDLE_WAIT
                      );

    // dissassembler
    // C_Q(BLAH) generates something that looks like `kBLAH: $write ("%5.5s ","kBLAH");
    // C_Q4 does it for four instructions
    `define C_Q(Y)  `k``Y: $write("%-5.5s ",`"Y`")
    `define C_Q2(E,F) `C_Q(E); `C_Q(F)
    `define C_Q3(E,F,G) `C_Q2(E,F); `C_Q(G)
    `define C_Q4(A,B,C,D)  `C_Q2(A,B); `C_Q2(C,D)
               unique casez (`ROOT.instruction)
                    `C_Q2(ADDU,SUBU);
                    `C_Q4(SLLV,SRAV,SRLV,AND);
                    `C_Q4(OR, NOR, SLT, SLTU);
                    `C_Q4(MOV,BAR,WAIT,BEQZ);
                    `C_Q4(BNEQZ,BGTZ,BLTZ,JALR);
                    `C_Q4(LW,LBU,SW,SB);
					`C_Q(NOP);
                  //`C_Q4(SINGLE);
                    default: $write("%-5.5s ","UNKWN");
               endcase 
			   
			   $write("%3.3x ", `ROOT.PC_r);
			   unique casez (`ROOT.fd_s_o.instruction_fd)
                    `C_Q2(ADDU,SUBU);
                    `C_Q4(SLLV,SRAV,SRLV,AND);
                    `C_Q4(OR, NOR, SLT, SLTU);
                    `C_Q4(MOV,BAR,WAIT,BEQZ);
                    `C_Q4(BNEQZ,BGTZ,BLTZ,JALR);
                    `C_Q4(LW,LBU,SW,SB);
					`C_Q(NOP);
                 // `C_Q4(SINGLE);
                    default: $write("%-5.5s ","UNKWN");
               endcase 
			   
			   $write("%3.3x ", `ROOT.fd_s_o.pc_fd);
			   $write("rs=%2.2x ", `ROOT.fd_s_o.instruction_fd.rs_imm);
			   $write("rd=%2.2x ", `ROOT.rd_read_addr);
			   $write("rs_val=%8.8x ", `ROOT.rs_val);
			   $write("rd_val=%8.8x ", `ROOT.rd_val);
			   unique casez (`ROOT.de_s_o.instruction_de)
                    `C_Q2(ADDU,SUBU);
                    `C_Q4(SLLV,SRAV,SRLV,AND);
                    `C_Q4(OR, NOR, SLT, SLTU);
                    `C_Q4(MOV,BAR,WAIT,BEQZ);
                    `C_Q4(BNEQZ,BGTZ,BLTZ,JALR);
                    `C_Q4(LW,LBU,SW,SB);
					`C_Q(NOP);
                 // `C_Q4(SINGLE);
                    default: $write("%-5.5s ","UNKWN");
               endcase 
			   
			   $write("%3.3x ", `ROOT.de_s_o.pc_de);
			   unique casez (`ROOT.em_s_o.instruction_em)
                    `C_Q2(ADDU,SUBU);
                    `C_Q4(SLLV,SRAV,SRLV,AND);
                    `C_Q4(OR, NOR, SLT, SLTU);
                    `C_Q4(MOV,BAR,WAIT,BEQZ);
                    `C_Q4(BNEQZ,BGTZ,BLTZ,JALR);
                    `C_Q4(LW,LBU,SW,SB);
					`C_Q(NOP);
                 // `C_Q4(SINGLE);
                    default: $write("%-5.5s ","UNKWN");
               endcase 
			   
			   $write("%3.3x ", `ROOT.em_s_o.pc_em);
			   unique casez (`ROOT.mw_s_o.instruction_mw)
                    `C_Q2(ADDU,SUBU);
                    `C_Q4(SLLV,SRAV,SRLV,AND);
                    `C_Q4(OR, NOR, SLT, SLTU);
                    `C_Q4(MOV,BAR,WAIT,BEQZ);
                    `C_Q4(BNEQZ,BGTZ,BLTZ,JALR);
                    `C_Q4(LW,LBU,SW,SB);
					`C_Q(NOP);
                 // `C_Q4(SINGLE);
                    default: $write("%-5.5s ","UNKWN");
               endcase 
			   
			   $write("%3.3x ", `ROOT.mw_s_o.pc_mw);
               $write("%2.2x %2.2x; "
                      , `ROOT.mw_s_o.instruction_mw.rd
                      , `ROOT.mw_s_o.instruction_mw.rs_imm
                      );

               if (`ROOT.rf_wen)
                 $write("RF[%2.2x] = %8.8x; "
                        , `ROOT.rd_addr
                        , `ROOT.rf_wd
                        );
               else
                 $write("       =         ; ");
               if (`ROOT.to_mem_o.valid)
                 begin
                    if (`ROOT.to_mem_o.wen)
                      $write("MEM%c[%8.8x] = %8.8x; "
                             , `ROOT.to_mem_o.byte_not_word ? "1" : "4"
                             , `ROOT.data_mem_addr
                             , `ROOT.to_mem_o.write_data
                             );
                    else
                      $write("MEM%c[%8.8x] READREQ; "
                             , `ROOT.to_mem_o.byte_not_word ? "1" : "4"
                             , `ROOT.data_mem_addr
                             );
                 end
               if (`ROOT.to_mem_o.yumi)
                 $write(" \\-> MEM YUMI (%8.8x); "
                        , `ROOT.from_mem_i.read_data);
               $write("\n");
            end
       end 
   `endif 

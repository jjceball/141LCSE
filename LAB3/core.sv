`include "definitions.sv"

module core #(parameter imem_addr_width_p=10
                       ,net_ID_p = 10'b0000000001)
             (input  clk
             ,input  reset
             ,input  net_packet_s net_packet_i
             ,output net_packet_s net_packet_o
             ,input  mem_out_s from_mem_i
             ,output mem_in_s  to_mem_o
             ,output logic [mask_length_gp-1:0] barrier_o
             ,output logic                      exception_o
             ,output debug_s                    debug_o
             ,output logic [31:0]               data_mem_addr
             );
			 
//---- Adresses and Data ----//
// Ins. memory address signals
logic [imem_addr_width_p-1:0] PC_r, PC_n,
                              pc_plus1, imem_addr,
                              imm_jump_add;
							  
// Ins. memory output
instruction_s instruction, imem_out, instruction_r;

// Result of ALU, Register file outputs, Data memory output data
logic [31:0] alu_result, rs_val_or_zero, rd_val_or_zero, rs_val, rd_val;

// Reg. File address
logic [($bits(instruction.rs_imm))-1:0] rd_addr;
logic [($bits(instruction.rs_imm))-1:0] rd_read_addr;

// Data for Reg. File signals
logic [31:0] rf_wd;

//---- Control signals ----//
// ALU output to determin whether to jump or not
logic jump_now;

// controller output signals
logic is_load_op_c,  op_writes_rf_c, valid_to_mem_c,
      is_store_op_c, is_mem_op_c,    PC_wen,
      is_byte_op_c,  PC_wen_r;

// Handshak protocol signals for memory
logic yumi_to_mem_c;

// Final signals after network interfere
logic imem_wen, rf_wen;

// Network operation signals
logic net_ID_match,      net_PC_write_cmd,  net_imem_write_cmd,
      net_reg_write_cmd, net_bar_write_cmd, net_PC_write_cmd_IDLE;

// Memory stages and stall signals
logic [1:0] mem_stage_r, mem_stage_n;
logic stall, stall_non_mem;

// Exception signal
logic exception_n;

// State machine signals
state_e state_r,state_n;

//---- network and barrier signals ----//
instruction_s net_instruction;
logic [mask_length_gp-1:0] barrier_r,      barrier_n,
                           barrier_mask_r, barrier_mask_n;

// Additions for forwarding implementation
						   
logic bubble;
logic flush;
logic IDLE_WAIT;
logic [1:0] wait_count;
logic [1:0] fwd_a,fwd_b,fwd_c;
logic [31:0] mem_write_data;

// REGISTERS
fd_pipeline_s fd_s_i, fd_s_o;
de_pipeline_s de_s_i, de_s_o;
em_pipeline_s em_s_i, em_s_o;
mw_pipeline_s mw_s_i, mw_s_o;

logic [31:0] rf_wd_mw_n;

// FIRST REGISTER
assign fd_s_i = '{instruction_fd    : instruction
                 ,pc_fd         	: PC_r
                 };
fd_register fd_reg(.clk(clk)
			 ,.stall(stall)
			 ,.flush(flush)
			 ,.bubble(bubble)
			 ,.IDLE_WAIT(IDLE_WAIT)
		     ,.fd_s_i(fd_s_i)
             ,.fd_s_o(fd_s_o)
			 );	 
always_comb
begin
	IDLE_WAIT = 1'b0;
	if(fd_s_o.instruction_fd==?`kWAIT || wait_count > 2'b00)
		IDLE_WAIT = 1'b1;
	else
		IDLE_WAIT = 1'b0;
end
always_ff @(posedge clk)
begin
	if(fd_s_o.instruction_fd==?`kWAIT)
		wait_count <= 2'b11;
	else if(wait_count > 2'b00)
		wait_count <= wait_count - 2'b01;
	else
		wait_count <= 2'b00;
end
 
// SECOND REGISTER
assign de_s_i = '{instruction_de	: fd_s_o.instruction_fd,
				  pc_de				: fd_s_o.pc_fd,
				  rs_val_de			: rs_val,
				  rd_val_de			: rd_val,
				  is_load_op_c_de	: is_load_op_c,
				  op_writes_rf_c_de : op_writes_rf_c,
				  is_store_op_c_de	: is_store_op_c,
				  is_mem_op_c_de	: is_mem_op_c,
				  is_byte_op_c_de	: is_byte_op_c
				 };			 
de_register de_reg(.clk(clk)
			 ,.stall(stall)
			 ,.flush(flush)
			 ,.bubble(bubble)
		     ,.de_s_i(de_s_i)
             ,.de_s_o(de_s_o)
			 );
				 
// THIRD REGISTER
assign em_s_i = '{instruction_em	: de_s_o.instruction_de,
				  pc_em				: de_s_o.pc_de,
				  alu_result_em		: alu_result,
				  rs_val_or_zero_em : rs_val_or_zero,
				  is_load_op_c_em	: de_s_o.is_load_op_c_de,
				  op_writes_rf_c_em : de_s_o.op_writes_rf_c_de,
				  is_store_op_c_em	: de_s_o.is_store_op_c_de,
				  is_mem_op_c_em	: de_s_o.is_mem_op_c_de,
				  is_byte_op_c_em	: de_s_o.is_byte_op_c_de
				 };			 
em_register em_reg(.clk(clk)
			 ,.stall(stall)
			 ,.em_s_i(em_s_i)
			 ,.em_s_o(em_s_o)
			 );
			 
// FORUTH REGISTER
assign mw_s_i = '{instruction_mw	: em_s_o.instruction_em,
				  pc_mw				: em_s_o.pc_em,
				  rf_wd_mw			: rf_wd_mw_n,
				  op_writes_rf_c_mw : em_s_o.op_writes_rf_c_em,
				  alu_result_mw		: em_s_o.alu_result_em,
				  is_load_op_c_mw	: em_s_o.is_load_op_c_em
				 };
always_comb
begin
	if (em_s_o.is_load_op_c_em)
		rf_wd_mw_n = from_mem_i.read_data;
	else
		rf_wd_mw_n = em_s_o.alu_result_em;
end				 
mw_register mw_reg(.clk(clk)
			 ,.stall(stall)
			 ,.mw_s_i(mw_s_i)
			 ,.mw_s_o(mw_s_o)
			 );
// END OF FIVE-STAGES

//---- Connection to external modules ----//

// Suppress warnings
assign net_packet_o = net_packet_i;

// Data_mem
assign to_mem_o = '{write_data    : mem_write_data
                   ,valid         : valid_to_mem_c
                   ,wen           : em_s_o.is_store_op_c_em
                   ,byte_not_word : em_s_o.is_byte_op_c_em
                   ,yumi          : yumi_to_mem_c
                   };

// DEBUG Struct
assign debug_o = {mw_s_o.pc_mw, mw_s_o.instruction_mw, state_r, barrier_mask_r, barrier_r};

// Insruction memory
instr_mem #(.addr_width_p(imem_addr_width_p)) imem
           (.clk(clk)
           ,.addr_i(imem_addr)
           ,.instruction_i(net_instruction)
           ,.wen_i(imem_wen)
           ,.instruction_o(imem_out)
           );

// Since imem has one cycle delay and we send next cycle's address, PC_n,
// if the PC is not written, the instruction must not change
assign instruction = (PC_wen_r) ? imem_out : instruction_r;

// Register file
reg_file #(.NUM_REG($bits(instruction.rs_imm))) rf
          (.clk(clk)
          ,.ra0_i(fd_s_o.instruction_fd.rs_imm)
          ,.ra1_i(rd_read_addr)
          ,.wen_i(rf_wen)
          ,.wd_i(rf_wd)  
          ,.rd0_o(rs_val)
          ,.rd1_o(rd_val)
			 ,.wa_i(rd_addr)
          );

// FORWARDING LOGIC

////////////////// FORWARD A //////////////////
always_comb
begin
	unique casez (fwd_a)
		2'b10:
			rs_val_or_zero = em_s_o.alu_result_em;
		2'b01:
			rs_val_or_zero = rf_wd;
		default:
			rs_val_or_zero = de_s_o.instruction_de.rs_imm ? de_s_o.rs_val_de : 32'b0;
	endcase
end	

////////////////// FORWARD B //////////////////
always_comb
begin
	unique casez(fwd_b)
		2'b10:
			rd_val_or_zero = em_s_o.alu_result_em;
		2'b01:
			rd_val_or_zero = rf_wd;
		default:
			rd_val_or_zero = de_s_o.instruction_de.rd     ? de_s_o.rd_val_de : 32'b0;
	endcase
end

////////////////// FORWARD C //////////////////
always_comb
begin
	unique casez(fwd_c)
		2'b10:
		begin
			data_mem_addr = mw_s_o.rf_wd_mw;
			mem_write_data = em_s_o.rs_val_or_zero_em;
		end
		2'b01:
		begin
			data_mem_addr = em_s_o.alu_result_em;
			mem_write_data = mw_s_o.rf_wd_mw;
		end
		default:
		begin
			data_mem_addr = em_s_o.alu_result_em;
			mem_write_data = em_s_o.rs_val_or_zero_em;
		end
	endcase
end

// ALU
alu alu_1 (.rd_i(rd_val_or_zero)
          ,.rs_i(rs_val_or_zero)
          ,.op_i(de_s_o.instruction_de)
          ,.result_o(alu_result)
          ,.jump_now_o(jump_now)
          );

// select the input data for Register file, from network, the PC_plus1 for JALR,
// Data Memory or ALU result
always_comb
  begin
    if (net_reg_write_cmd)
      rf_wd = net_packet_i.net_data;
    else if (mw_s_o.instruction_mw==?`kJALR)
      rf_wd = mw_s_o.pc_mw + 1;
    else
      rf_wd = mw_s_o.rf_wd_mw;
  end

// Determine next PC
assign pc_plus1     = PC_r + 1'b1;
assign imm_jump_add = $signed(de_s_o.instruction_de.rs_imm)  + $signed(de_s_o.pc_de);

// Next pc is based on network or the instruction
always_comb
  begin
    PC_n = pc_plus1;
    
	if (net_PC_write_cmd_IDLE)
      PC_n = net_packet_i.net_addr;
    else
      unique casez (de_s_o.instruction_de)
        `kJALR: 
		  if(fwd_a == 2'b10)
			PC_n = em_s_o.alu_result_em;
		  else
			PC_n = alu_result[0+:imem_addr_width_p];
        `kBNEQZ,`kBEQZ,`kBLTZ,`kBGTZ: 
          if (jump_now)
            PC_n = imm_jump_add;
        default: begin end
      endcase
  end
  
always_comb
begin
	if(de_s_o.instruction_de==?`kJALR)
		flush = 1'b1;
	else
		flush = jump_now;
end

// HAZARD DETECTION 
detect_hazards hazard (.is_load_op_o(is_load_op_c),
					.is_store_op_o(is_store_op_c),
					.fd_s_o(fd_s_o),
					.de_s_o(de_s_o),
					.em_s_o(em_s_o),
					.mw_s_o(mw_s_o),
					.bubble(bubble),
					.fwd_a(fwd_a),
					.fwd_b(fwd_b),
					.fwd_c(fwd_c)
                  );

assign PC_wen = (net_PC_write_cmd_IDLE || (~stall && ~bubble && ~IDLE_WAIT) || flush);

// Sequential part, including PC, barrier, exception and state
always_ff @ (posedge clk)
  begin
    if (!reset)
      begin
        PC_r            <= 0;
        barrier_mask_r  <= {(mask_length_gp){1'b0}};
        barrier_r       <= {(mask_length_gp){1'b0}};
        state_r         <= IDLE;
        instruction_r   <= 0;
        PC_wen_r        <= 0;
        exception_o     <= 0;
        mem_stage_r     <= 2'b00;
      end
    else
      begin
        if (PC_wen)
          PC_r         <= PC_n;
        barrier_mask_r <= barrier_mask_n;
        barrier_r      <= barrier_n;
        state_r        <= state_n;
        instruction_r  <= instruction;
        PC_wen_r       <= PC_wen;
        exception_o    <= exception_n;
        mem_stage_r    <= mem_stage_n;
      end
  end

// stall and memory stages signals
// rf structural hazard and imem structural hazard (can't load next instruction)
assign stall_non_mem = (net_reg_write_cmd && mw_s_o.op_writes_rf_c_mw)
                    || (net_imem_write_cmd);
// Stall if LD/ST still active; or in non-RUN state
assign stall = stall_non_mem || (mem_stage_n != 2'b00) || (state_r != RUN);

// Launch LD/ST
assign valid_to_mem_c = em_s_o.is_mem_op_c_em & (mem_stage_r < 2'b10);

always_comb
  begin
    yumi_to_mem_c = 1'b0;
    mem_stage_n   = mem_stage_r;
    if (valid_to_mem_c)
        mem_stage_n   = 2'b01;
    if (from_mem_i.yumi)
        mem_stage_n   = 2'b10;
    if (from_mem_i.valid & ~stall_non_mem)
      begin
        mem_stage_n   = 2'b00;
        yumi_to_mem_c = 1'b1;
      end
  end

// Decode module
cl_decode decode (.instruction_i(fd_s_o.instruction_fd)
                  ,.is_load_op_o(is_load_op_c)
                  ,.op_writes_rf_o(op_writes_rf_c)
                  ,.is_store_op_o(is_store_op_c)
                  ,.is_mem_op_o(is_mem_op_c)
                  ,.is_byte_op_o(is_byte_op_c)
                  );

// State machine
cl_state_machine state_machine (.instruction_i(mw_s_o.instruction_mw)
                               ,.state_i(state_r)
                               ,.exception_i(exception_o)
                               ,.net_PC_write_cmd_IDLE_i(net_PC_write_cmd_IDLE)
                               ,.stall_i(stall)
                               ,.state_o(state_n)
                               );
							   
//---- Datapath with network ----//
// Detect a valid packet for this core
assign net_ID_match = (net_packet_i.ID==net_ID_p);

// Network operation
assign net_PC_write_cmd      = (net_ID_match && (net_packet_i.net_op==PC));
assign net_imem_write_cmd    = (net_ID_match && (net_packet_i.net_op==INSTR));
assign net_reg_write_cmd     = (net_ID_match && (net_packet_i.net_op==REG));
assign net_bar_write_cmd     = (net_ID_match && (net_packet_i.net_op==BAR));
assign net_PC_write_cmd_IDLE = (net_PC_write_cmd && (state_r==IDLE));

// Barrier final result, in the barrier mask, 1 means not mask and 0 means mask
assign barrier_o = barrier_mask_r & barrier_r;

// The instruction write is just for network
assign imem_wen  = net_imem_write_cmd;

// Register write could be from network or the controller
assign rf_wen    = (net_reg_write_cmd || (mw_s_o.op_writes_rf_c_mw && ~stall));

// Selection between network and core for instruction address
assign imem_addr = (net_imem_write_cmd) ? net_packet_i.net_addr
                                       : PC_n;

// Selection between network and address included in the instruction which is exeuted
// Address for Reg. File is shorter than address of Ins. memory in network data
// Since network can write into immediate registers, the address is wider
// but for the destination register in an instruction the extra bits must be zero
assign rd_addr = (net_reg_write_cmd)
                 ? (net_packet_i.net_addr [0+:($bits(instruction.rs_imm))])
                 : ({{($bits(instruction.rs_imm)-$bits(instruction.rd)){1'b0}}
                    ,{mw_s_o.instruction_mw.rd}});
					
assign rd_read_addr = (net_reg_write_cmd)
                 ? (net_packet_i.net_addr [0+:($bits(instruction.rs_imm))])
                 : ({{($bits(instruction.rs_imm)-$bits(instruction.rd)){1'b0}}
                    ,{fd_s_o.instruction_fd.rd}});

// Instructions are shorter than 32 bits of network data
assign net_instruction = net_packet_i.net_data [0+:($bits(instruction))];

// barrier_mask_n, which stores the mask for barrier signal
always_comb
  // Change PC packet
  if (net_bar_write_cmd && (state_r != ERR))
    barrier_mask_n = net_packet_i.net_data [0+:mask_length_gp];
  else
    barrier_mask_n = barrier_mask_r;

// barrier_n signal, which contains the barrier value
// it can be set by PC write network command if in IDLE
// or by an an BAR instruction that is committing
assign barrier_n = net_PC_write_cmd_IDLE
                   ? net_packet_i.net_data[0+:mask_length_gp]
                   : ((mw_s_o.instruction_mw==?`kBAR) & ~stall)
                     ? mw_s_o.alu_result_mw [0+:mask_length_gp]
                     : barrier_r;

// exception_n signal, which indicates an exception
// We cannot determine next state as ERR in WORK state, since the instruction
// must be completed, WORK state means start of any operation and in memory
// instructions which could take some cycles, it could mean wait for the
// response of the memory to aknowledge the command. So we signal that we recieved
// a wrong package, but do not stop the execution. Afterwards the exception_r
// register is used to avoid extra fetch after this instruction.
always_comb
  if ((state_r==ERR) || (net_PC_write_cmd && (state_r!=IDLE)))
    exception_n = 1'b1;
  else
    exception_n = exception_o;

endmodule

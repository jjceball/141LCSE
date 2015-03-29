`include "definitions.sv"

module detect_hazards
(
		input logic is_load_op_o,
		input logic is_store_op_o,
		input fd_pipeline_s fd_s_o,
		input de_pipeline_s de_s_o,
		input em_pipeline_s em_s_o,
		input mw_pipeline_s mw_s_o,
		output logic bubble,
		output logic [1:0] fwd_a,
		output logic [1:0] fwd_b,
		output logic [1:0] fwd_c
);

always_comb
begin
	if (em_s_o.op_writes_rf_c_em && em_s_o.instruction_em.rd &&
		(em_s_o.instruction_em.rd == de_s_o.instruction_de.rs_imm))
			fwd_a = 2'b10;
	else if (mw_s_o.op_writes_rf_c_mw && mw_s_o.instruction_mw.rd &&
			~(em_s_o.op_writes_rf_c_em && em_s_o.instruction_em.rd &&
			 (em_s_o.instruction_em.rd == de_s_o.instruction_de.rs_imm)) &&
			 (mw_s_o.instruction_mw.rd == de_s_o.instruction_de.rs_imm))
			fwd_a = 2'b01;
	else
			fwd_a = 2'b00;
end

always_comb
begin
	if (em_s_o.op_writes_rf_c_em && em_s_o.instruction_em.rd &&
		(em_s_o.instruction_em.rd === de_s_o.instruction_de.rd))
			fwd_b = 2'b10;
	else if (mw_s_o.op_writes_rf_c_mw && mw_s_o.instruction_mw.rd &&
			~(em_s_o.op_writes_rf_c_em && em_s_o.instruction_em.rd &&
			 (em_s_o.instruction_em.rd === de_s_o.instruction_de.rd)) &&
			 (mw_s_o.instruction_mw.rd === de_s_o.instruction_de.rd))
			fwd_b = 2'b01;
	else
			fwd_b = 2'b00;
end

always_comb
begin
	if (mw_s_o.is_load_op_c_mw && em_s_o.is_mem_op_c_em)
	begin
		if (mw_s_o.instruction_mw.rd == em_s_o.instruction_em.rd)
			fwd_c = 2'b10;
		else if(mw_s_o.instruction_mw.rd == em_s_o.instruction_em.rs_imm)
			fwd_c = 2'b01;
		else
			fwd_c = 2'b00;
	end
	else
		fwd_c = 2'b00;
end

always_comb
begin
	bubble = 1'b0;
	if (de_s_o.is_load_op_c_de &&
		((de_s_o.instruction_de.rd == fd_s_o.instruction_fd.rd) ||
		 (de_s_o.instruction_de.rd == fd_s_o.instruction_fd.rs_imm)))
			bubble = 1'b1;
end

endmodule

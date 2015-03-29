`include "definitions.sv"

module de_register
(
	 input logic clk,
	 input logic stall,
	 input logic flush,
	 input logic bubble,
	 input de_pipeline_s de_s_i,
	 output de_pipeline_s de_s_o
);

always_ff @(posedge clk) 
begin
	if (stall)
		begin
			de_s_o <= de_s_o;
		end
	else
		begin
			if (flush | bubble)
				begin
					de_s_o.instruction_de <= `kNOP;
					de_s_o.pc_de <= de_s_o.pc_de;
					de_s_o.rs_val_de <= 32'b0;
					de_s_o.rd_val_de <= 32'b0;
					de_s_o.is_load_op_c_de <= 1'b0;
					de_s_o.op_writes_rf_c_de <= 1'b0;
					de_s_o.is_store_op_c_de <= 1'b0;
					de_s_o.is_mem_op_c_de <= 1'b0;
					de_s_o.is_byte_op_c_de <= 1'b0;
				end
			else 
				de_s_o <= de_s_i;
		end
end

endmodule

`include "definitions.sv"

module em_register
(
		input logic clk,
		input logic stall,
		input em_pipeline_s em_s_i,
		output em_pipeline_s em_s_o
);

always_ff @(posedge clk)
begin
	if (stall)
		em_s_o <= em_s_o;
	else
		em_s_o <= em_s_i;
end

endmodule

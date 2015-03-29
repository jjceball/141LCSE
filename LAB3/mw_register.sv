`include "definitions.sv"

module mw_register
(
		input logic clk,
		input logic stall,
		input mw_pipeline_s mw_s_i,
		output mw_pipeline_s mw_s_o
);

always_ff @(posedge clk) 
begin
	if (stall)
		mw_s_o <= mw_s_o;
	else
		mw_s_o <= mw_s_i;
end

endmodule

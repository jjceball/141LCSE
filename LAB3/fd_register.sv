`include "definitions.sv"

module fd_register
(
		input logic clk,
		input logic stall,
		input logic flush,
		input logic bubble,
		input logic IDLE_WAIT,
		input fd_pipeline_s fd_s_i,
		output fd_pipeline_s fd_s_o
);

always_ff @(posedge clk) 
begin
	if (stall | bubble)
		fd_s_o <= fd_s_o;
	else
	begin
		if (flush | IDLE_WAIT)
		begin
			fd_s_o.instruction_fd <= `kNOP;
			fd_s_o.pc_fd <= fd_s_o.pc_fd;
		end
		else 
			fd_s_o <= fd_s_i;
	end
end

endmodule

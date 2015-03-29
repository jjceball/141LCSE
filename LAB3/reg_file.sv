module reg_file#(parameter NUM_REG = 6, BITS = 32)
(
	input clk,
	input wen_i,
	input [NUM_REG - 1 : 0] wa_i,
	input [BITS - 1 : 0] wd_i,
	input [NUM_REG - 1 : 0] ra0_i,
	input [NUM_REG - 1 : 0] ra1_i,
	output [BITS - 1 : 0] rd0_o,
	output [BITS - 1 : 0] rd1_o
);

 logic [BITS - 1 : 0] rf [2**NUM_REG - 1 : 0];
 logic [BITS - 1 : 0] rd0_n, rd1_n;
 
 always_comb
 begin
	if((wa_i == ra0_i) && wen_i)
		rd0_n = wd_i;
	else
		rd0_n = rf[ra0_i];
	if((wa_i == ra1_i) && wen_i)
		rd1_n = wd_i;
	else
		rd1_n = rf[ra1_i];
 end
 
 assign rd0_o = rd0_n;
 assign rd1_o = rd1_n;

always_ff @(posedge clk)
begin
	if(wen_i)
	begin
		rf[wa_i] <= wd_i;
	end
end

endmodule

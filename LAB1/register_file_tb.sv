`timescale 1ns / 1ps

/*
 * Register_File Testbench
 * 
 * Author: Jay Ceballos
 * PID: A09338030
 * Email: jjceball@ucsd.edu 
 * 
 */

module register_file_tb#(parameter R=256,W=32,L=8); 

   logic         clk;
	logic 		  wen_i;
   logic [W-1:0] a_r;
   logic [W-1:0] b_r;

   // The design under test is the Register_File
   Register_file dut (   .clk(clk)
	        ,.wa_i(wa_i)
	        ,.ra0_i(ra0_i)
           ,.ra1_i(ra1_i)
			  ,.wd_i(wd_i)
					,.rd0_o(rd0_o)
					,.rd1_o(rd1_o)
             );
				 
   // Toggle the clock every 10 ns

   initial
     begin
        clk = 0;
        forever #10 clk = !clk;
     end

   // Test with a variety of inputs.
   // Introduce new stimulus on the falling clock edge so that values
   // will be on the input wires in plenty of time to be read by
   // registers on the subsequent rising clock edge.
   initial
     begin
        a_r = 0;
        b_r = 0;
        @(negedge clk);
        a_r = 1;
        b_r = 1;
        @(negedge clk);
        a_r = 5;
        b_r = 6;
        @(negedge clk);
        a_r = 2;
        b_r = 2;
        @(negedge clk);
        a_r = 3;
        b_r = 3;
        @(negedge clk);
        a_r = 1;
        b_r = 8;
     end // initial begin

endmodule // Register_file_tb
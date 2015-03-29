/*
 * Register_file
 *
 * Author: Jay Ceballos
 * PID: A09338030
 * Email: jjceball@ucsd.edu
 *
 */

`timescale 1ns / 1ps

module register_file#(parameter R=256,W=32,L=8) 
//R = # of Registers, W = Bits of the register, L = Log of R 
(  
  input clk, wen_i,
  input [L-1:0] wa_i,ra0_i,ra1_i,
  input [W-1:0] wd_i,
  
  output [W-1:0] rd0_o,rd1_o
);

  logic [W-1:0] rf [R-1:0];
  
  assign rd0_o = rf[ra0_i];
  assign rd1_o = rf[ra1_i];
    
  always_ff @( posedge clk )
  begin
    if (wen_i)
		rf[wa_i] <= wd_i;
  end
endmodule
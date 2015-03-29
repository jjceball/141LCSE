`timescale 1ns / 1ps
//
// CSE141L Lab
// University of California, San Diego
// 
// Written by Michael Taylor, May 1, 2010
// Modified by Nikolaos Strikos, April 8, 2012
//
//
// parameters:
// 	width_p:    width of data coming in and out
//      lg_depth_p: lg (number of elements+1)
//
// note: one element goes unused; so lg_depth_p=3 means 7 elements
// lg_depth_p=2 means 3 elements, etc.

module mbt_fifo#(parameter width_p=27, lg_depth_p=3)
(
	input clk,
	input [width_p - 1:0] d_i,
	input enque_i, 
	input deque_i,	
	input clear_i,
	output [width_p - 1:0] d_o,
	output empty_o,
	output full_o,
	output valid_o
);

// some storage
logic [width_p - 1:0] storage [(2**lg_depth_p)-1:0];

// one read pointer, one write pointer;
logic [lg_depth_p-1:0] rptr_r, wptr_r;

logic error_r; // lights up if the fifo was used incorrectly

assign full_o = ((wptr_r + 1'b1) == rptr_r);
assign empty_o = (wptr_r == rptr_r);
assign valid_o = !empty_o;

assign d_o = storage[rptr_r];

always_ff @(posedge clk)
 if (enque_i)
	storage[wptr_r] <= d_i;

always_ff @(posedge clk)
  begin
     if (clear_i)
		begin
			rptr_r <= 0;
			wptr_r <= 0;
			error_r <= 1'b0;
		end
     else
		begin
			rptr_r <= rptr_r + deque_i;
			wptr_r <= wptr_r + enque_i;

			// synthesis translate off

			if (full_o & enque_i)
					$display("error: wrote full fifo");
			if (empty_o & deque_i)
					$display("error: deque empty fifo");			

			// synthesis translate on				
								
			error_r  <= error_r | (full_o & enque_i) | (empty_o & deque_i);
		end 
  end
endmodule
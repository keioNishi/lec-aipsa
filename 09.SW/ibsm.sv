`include "sw.svh"
module isbm(
	input  logic [1:0]     pout,
	output logic           re,
	input  logic           empty,
	input  logic [`PORT:0] reqi,
	output logic [`PORT:0] req,
	input  logic           ack,
	input  logic           clk, rst
);
	typedef enum {INIT, AREQ, XFER} ISBMTYPE;
	ISBMTYPE state, nstate;
//
//
//
//
//
//
//
//
//
endmodule

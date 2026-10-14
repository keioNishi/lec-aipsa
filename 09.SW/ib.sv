`include "sw.svh"
module ib(
	input  logic [`PKTW:0] pkti,
	output logic [`PKTW:0] pkto,
	output logic [`PORT:0] req,
	input  logic           ack,
	output logic           full,
	input  logic           clk, rst
);
	logic [`PORT:0] reqi;
	logic we, re, empty;
	mkwe mkwe(pkti, we);
	fifo fifo(pkti, we, full, pkto, re, empty, clk, rst);
	isbm isbm(pkto[`FLOWBH:`FLOWBL], re, empty, reqi, req, ack, clk, rst);
	mkreq mkreq(pkto, reqi, clk, rst);
endmodule


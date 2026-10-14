`include "sw.svh"
module mkreq(
	input  logic [`PKTW:0] pkti,
	output logic [`PORT:0] req,
	input  logic           clk, rst
);
	logic [`PORT:0] reqp;
	always_comb begin
		reqp = 0;
		reqp[pkti[1:0]] = `ASSERT;
	end
	always_ff @(posedge clk or posedge rst) begin
		if(rst) req <= 0;
		else begin
			if(pkti[`FLOWBH:`FLOWBL] == `HEAD) begin
				req <= reqp;
			end
		end
	end
endmodule

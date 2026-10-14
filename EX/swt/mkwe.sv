`include "sw.svh"
module mkwe(
	input  logic [`PKTW:0] pkti,
	output logic           we
);
	always_comb begin
		if(pkti[`FLOWBH:`FLOWBL] == `EMPT) we = `NEGATE;
		else we = `ASSERT;
	end
endmodule

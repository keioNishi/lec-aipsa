module sel(
	input  logic ia, ib, sel,
	output logic out
);
	always_comb
		if(sel == 1'b1) out = ia;
		else out = ib;
endmodule

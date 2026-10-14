module ackor(
	input  logic a0, a1, a2, a3,
	output logic ao
);
	assign ao = a0 | a1 | a2 | a3;
endmodule

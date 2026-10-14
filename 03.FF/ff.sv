module ff(
	input  logic d,
	output logic q,
	input  logic clk
);
	always_ff @(posedge clk) begin
		q <= d;
	end
endmodule

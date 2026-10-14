module state(
	input  logic       a, b,
	output logic [1:0] floor,
	input  logic       clk, rst
);
	logic [1:0] s, ns;
	always_ff @(posedge clk)
		if(rst) s <= 0;
		else s <= ns;
	// floor depends only on the state (Moore output), so it is assigned in
	// every state; leaving it unassigned would infer a latch.
	// `unique case` replaces "synopsys full_case parallel_case"; the unused
	// state 2'b10 is a don't-care ('x).
	always_comb begin
		ns = s;
		floor = 'x;
		unique case(s)
		2'b00:begin
			floor = 1;
			if({a, b} == 2'b10) ns = 2'b01;
		end
		2'b01:begin
			floor = 2;
			if({a, b} == 2'b10) ns = 2'b11;
			if({a, b} == 2'b01) ns = 2'b00;
		end
		2'b11:begin
			floor = 3;
			if({a, b} == 2'b01) ns = 2'b01;
		end
		default: ;
		endcase
	end
endmodule

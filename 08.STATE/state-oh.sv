module state(
	input  logic       a, b,
	output logic [1:0] floor,
	input  logic       clk, rst
);
	logic [2:0] s, ns;
	always_ff @(posedge clk)
		if(rst) s <= 3'b001;
		else s <= ns;
	// One-hot "reverse case": `unique case(1)` states that exactly one state
	// bit is set (replaces "synopsys full_case parallel_case"); any other
	// pattern is a don't-care ('x).
	always_comb begin
		ns = 'x;
		floor = 'x;
		unique case(1'b1)
		s[0]: begin
			floor = 1;
			case({a,b})
			2'b00: ns = 3'b001;
			2'b01: ns = 3'b001;
			2'b10: ns = 3'b010;
			2'b11: ns = 3'b001;
			endcase
		end
		s[1]: begin
			floor = 2;
			case({a,b})
			2'b00: ns = 3'b010;
			2'b01: ns = 3'b001;
			2'b10: ns = 3'b100;
			2'b11: ns = 3'b010;
			endcase
		end
		s[2]: begin
			floor = 3;
			case({a,b})
			2'b00: ns = 3'b100;
			2'b01: ns = 3'b010;
			2'b10: ns = 3'b100;
			2'b11: ns = 3'b100;
			endcase
		end
		default: ;
		endcase
	end
endmodule

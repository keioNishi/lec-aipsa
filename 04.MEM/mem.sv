module mem(
	input  logic [1:0] ra, wa,
	input  logic [7:0] wd,
	output logic [7:0] rd,
	input  logic       we,
	input  logic       clk
);
	logic [7:0] mem [3:0];
	assign rd = mem[ra];
	always_ff @(posedge clk) begin
		if(we) mem[wa] <= wd;
	end
endmodule

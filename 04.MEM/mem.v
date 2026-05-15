module mem(ra, wa, wd, rd, we, clk);
	input [1:0] ra, wa;
	input [7:0] wd;
	output [7:0] rd;
	input we;
	input clk;
	logic [7:0] mem [3:0];
	assign rd = mem[ra];
	always@(posedge clk) begin
		if(we) mem[wa] <= wd;
	end
endmodule

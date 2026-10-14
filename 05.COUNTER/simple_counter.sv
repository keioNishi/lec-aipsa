module simple_counter(
	output logic [2:0] count,
	input  logic       clk,
	input  logic       rst
);
	always_ff @(posedge clk) begin
		if(rst) count <= 0;
		else count <= count + 1;
	end
endmodule

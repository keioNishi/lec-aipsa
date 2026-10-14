module fifo(
	input  logic [7:0] in,
	input  logic       we,
	output logic       full,
	output logic [7:0] out,
	input  logic       re,
	output logic       empty,
	input  logic       clk, rst
);
	logic [7:0] mem[7:0];
	logic [2:0] head, tail, headi;
	always_ff @(posedge clk) begin
		if(rst) begin
			head <= 0;
			tail <= 0;
		end else begin
			if(we) head <= head + 1;
			if(re) tail <= tail + 1;
		end
	end
	always_ff @(posedge clk)
		if(we) mem[head] <= in;
	assign out = mem[tail];
	always_comb begin
		empty = 1'b0;
		full = 1'b0;
		headi = head + 1;
		if(head == tail) empty = 1'b1;
		if(headi == tail) full = 1'b1;
	end
endmodule

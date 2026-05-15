module simple_counter(output logic [2:0] count, input clk, input rst);
	always @(posedge clk) begin
		if(rst) count <= 0;
		else count <= count + 1;
	end
endmodule

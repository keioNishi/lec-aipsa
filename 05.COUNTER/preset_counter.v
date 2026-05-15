module preset_counter(input en, input [2:0] val, output logic [3:0] count, input clk, input rst);
	always @(posedge clk) begin
		if(rst) count <= 0;
		else
			if(en) begin
				if(count != 0) count <= count - 1;
			end else
				count <= val;
	end
endmodule

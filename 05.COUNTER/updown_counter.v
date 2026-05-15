module updown_counter(input ud, output logic [3:0] count, input clk, input rst);
	always @(posedge clk) begin
		if(rst) count <= 0;
		else
			if(ud) begin
				if(count != 7) count <= count + 1;
			end else
				if(count != 0) count <= count - 1;
	end
endmodule

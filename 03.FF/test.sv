`timescale 1ns/10ps
module test;
	logic d, q, clk;
	ff ff0(.d(d), .q(q), .clk(clk));

	always #5 clk = ~clk;
initial begin
$dumpfile("test.vcd");
$dumpvars(0, test);
clk = 0;
d = 1;
#20
d = 0;
#13
d = 1;
#20
$finish();
end
endmodule

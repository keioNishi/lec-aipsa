`timescale 1ns/10ps
module test;
	logic [1:0] ra, wa;
	logic [7:0] rd, wd;
	logic we, clk;
	always #10 clk = ~clk;
	mem mem(ra, wa, wd, rd, we, clk);
initial begin
$dumpfile("mem.vcd");
$dumpvars(0, test);
clk = 0;
ra = 0;
we = 0;
wa = 0;
wd = 111;
#50
we = 1;
#20
$finish;
end
endmodule

`timescale 1ns/10ps
module test;
	logic ud, clk, rst;
	wire [3:0] count;
	updown_counter updown_counter(ud, count, clk, rst);
	always #5 clk = ~clk;
initial begin
$dumpfile("updown_counter.vcd");
$dumpvars(0, test);
clk = 0;
rst = 1;
ud = 1;
#20
rst = 0;
#120
ud = 0;
#120
$finish();
end
endmodule

`timescale 1ns/10ps
module test;
	logic en, clk, rst;
	logic [2:0] val;
	logic [3:0] count;
	preset_counter preset_counter(en, val, count, clk, rst);
	always #5 clk = ~clk;
initial begin
$dumpfile("preset_counter.vcd");
$dumpvars(0, test);
clk = 0;
rst = 1;
val = 14;
en = 0;
#20
rst = 0;
#10
en = 1;
#120
en = 0;
#10
en = 1;
#120
$finish();
end
endmodule

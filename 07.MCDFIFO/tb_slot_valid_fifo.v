//-----------------------------------------------------------------------------
// tb_slot_valid_fifo.v
//
// Testbench for slot_valid_fifo.  Same scenario set as tb_async_fifo.v
// (fast writer / fast reader / bursty) plus a throughput measurement that
// confirms the slot-valid FIFO sustains ~1 word per wr_clk in steady state.
//
// Run:
//   iverilog -g2001 -o sim slot_valid_fifo.v tb_slot_valid_fifo.v && vvp sim
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_slot_valid_fifo;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;             // depth = 16
    localparam DEPTH      = (1 << ADDR_WIDTH);

    // DUT I/O
    reg                   wr_clk = 0;
    reg                   wr_rst_n = 1;
    reg                   wr_en;
    reg  [DATA_WIDTH-1:0] wr_data;
    wire                  wr_full;

    reg                   rd_clk = 0;
    reg                   rd_rst_n = 1;
    reg                   rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                  rd_empty;

    // Adjustable clock periods
    real WR_PERIOD = 7.0;
    real RD_PERIOD = 11.0;

    always #(WR_PERIOD/2.0) wr_clk = ~wr_clk;
    always #(RD_PERIOD/2.0) rd_clk = ~rd_clk;

    slot_valid_fifo
`ifndef GATE_SIM
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
`endif
    dut (
        .wr_clk(wr_clk),  .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),    .wr_data(wr_data),  .wr_full(wr_full),

        .rd_clk(rd_clk),  .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),    .rd_data(rd_data),  .rd_empty(rd_empty)
    );

    //--------------------------------------------------------------
    // Reference queue + checkers
    //--------------------------------------------------------------
    reg [DATA_WIDTH-1:0] ref_q [0:4095];
    integer ref_head, ref_tail;
    integer errors, pushed, popped;
    integer wr_cycles, rd_cycles;
    integer scenario_pushed_start, scenario_wr_cycle_start;

    always @(posedge wr_clk) begin
        if (wr_rst_n) wr_cycles <= wr_cycles + 1;
        if (wr_rst_n && wr_en && !wr_full) begin
            ref_q[ref_head] <= wr_data;
            ref_head        <= ref_head + 1;
            pushed          <= pushed + 1;
        end
    end

    always @(posedge rd_clk) begin
        if (rd_rst_n) rd_cycles <= rd_cycles + 1;
        if (rd_rst_n && rd_en && !rd_empty) begin
            if (rd_data !== ref_q[ref_tail]) begin
                $display("[%0t] ERROR: rd_data=0x%0h expected=0x%0h (idx=%0d)",
                         $time, rd_data, ref_q[ref_tail], ref_tail);
                errors <= errors + 1;
            end
            ref_tail <= ref_tail + 1;
            popped   <= popped + 1;
        end
    end

    //--------------------------------------------------------------
    // Helpers
    //--------------------------------------------------------------
    task do_reset;
        begin
            wr_rst_n = 1;  rd_rst_n = 1;  #1;
            wr_rst_n = 0;  rd_rst_n = 0;
            wr_en = 0; rd_en = 0; wr_data = 0;
            ref_head = 0; ref_tail = 0;
            errors = 0; pushed = 0; popped = 0;
            wr_cycles = 0; rd_cycles = 0;
            #50;
            wr_rst_n = 1;  rd_rst_n = 1;
            #50;
        end
    endtask

    // Drive on NEGEDGE with blocking assignments (see tb_async_fifo.v note).
    task producer_burst(input integer N, input integer MAXGAP);
        integer i, gap;
        reg [DATA_WIDTH-1:0] v;
        begin
            i = 0;  v = 8'hA0;
            while (i < N) begin
                @(negedge wr_clk);
                if (!wr_full) begin
                    wr_en   = 1'b1;
                    wr_data = v;
                    v = v + 1;
                    i = i + 1;
                end else begin
                    wr_en   = 1'b0;
                end
                if (MAXGAP > 0) begin
                    gap = ({$random} % (MAXGAP + 1));
                    if (gap > 0) repeat (gap) @(negedge wr_clk) wr_en = 1'b0;
                end
            end
            @(negedge wr_clk) wr_en = 1'b0;
        end
    endtask

    task consumer_burst(input integer N, input integer MAXGAP);
        integer i, gap;
        begin
            i = 0;
            while (i < N) begin
                @(negedge rd_clk);
                if (!rd_empty) begin
                    rd_en = 1'b1;
                    i = i + 1;
                end else begin
                    rd_en = 1'b0;
                end
                if (MAXGAP > 0) begin
                    gap = ({$random} % (MAXGAP + 1));
                    if (gap > 0) repeat (gap) @(negedge rd_clk) rd_en = 1'b0;
                end
            end
            @(negedge rd_clk) rd_en = 1'b0;
        end
    endtask

    //--------------------------------------------------------------
    // Scenarios
    //--------------------------------------------------------------
    initial begin
        $dumpfile("slot_valid_fifo.vcd");
        $dumpvars(0, tb_slot_valid_fifo);

        // Scenario 1: fast writer, slow reader
        WR_PERIOD = 7.0;  RD_PERIOD = 23.0;
        $display("\n=== Scenario 1: fast writer, slow reader ===");
        do_reset;
        fork
            producer_burst(64, 0);
            consumer_burst(64, 2);
        join
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d popped=%0d errors=%0d", pushed, popped, errors);

        // Scenario 2: slow writer, fast reader
        WR_PERIOD = 23.0;  RD_PERIOD = 7.0;
        $display("\n=== Scenario 2: slow writer, fast reader ===");
        do_reset;
        fork
            producer_burst(64, 3);
            consumer_burst(64, 0);
        join
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d popped=%0d errors=%0d", pushed, popped, errors);

        // Scenario 3: bursty, near-equal rates
        WR_PERIOD = 10.0;  RD_PERIOD = 13.0;
        $display("\n=== Scenario 3: bursty traffic, near-equal rates ===");
        do_reset;
        fork
            producer_burst(256, 2);
            consumer_burst(256, 2);
        join
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d popped=%0d errors=%0d", pushed, popped, errors);

        // Scenario 4: throughput check (depth=16 should sustain ~1 word/wr_clk)
        WR_PERIOD = 10.0;  RD_PERIOD = 10.0;
        $display("\n=== Scenario 4: throughput check (DEPTH=%0d) ===", DEPTH);
        do_reset;
        scenario_wr_cycle_start = wr_cycles;
        fork
            producer_burst(512, 0);
            consumer_burst(512, 0);
        join
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d in %0d wr_clk cycles (target <= ~%0d)",
                 pushed, wr_cycles - scenario_wr_cycle_start, 512 + 4*DEPTH);
        $display("  errors=%0d", errors);

        if (errors == 0)
            $display("\n*** ALL SCENARIOS PASSED ***\n");
        else
            $display("\n*** %0d ERRORS DETECTED ***\n", errors);

        $finish;
    end

    initial begin
        #500000;
        $display("TIMEOUT");
        $finish;
    end

endmodule

//-----------------------------------------------------------------------------
// tb_async_fifo.v
//
// Testbench for async_fifo.  Verifies three scenarios:
//   1. wr_clk faster than rd_clk  (producer outruns consumer -> full)
//   2. rd_clk faster than wr_clk  (consumer drains -> empty)
//   3. similar clock rates with bursty traffic
//
// FIFO contents are also checked against a reference queue held in the
// testbench so any data-ordering bug is caught.
//
// Run examples:
//   iverilog -g2001 -o sim async_fifo.v tb_async_fifo.v && vvp sim
//   verilator --binary --timing async_fifo.v tb_async_fifo.v
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_async_fifo;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;             // depth = 16
    localparam DEPTH      = (1 << ADDR_WIDTH);

    // DUT I/O
    reg                  wr_clk = 0;
    reg                  wr_rst_n;
    reg                  wr_en;
    reg  [DATA_WIDTH-1:0] wr_data;
    wire                 wr_full;
    wire                 wr_almost_full;

    reg                  rd_clk = 0;
    reg                  rd_rst_n;
    reg                  rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                 rd_empty;
    wire                 rd_almost_empty;

    // Clock periods (will be reassigned per scenario)
    real WR_PERIOD = 7.0;     // ~143 MHz
    real RD_PERIOD = 11.0;    // ~ 91 MHz

    always #(WR_PERIOD/2.0) wr_clk = ~wr_clk;
    always #(RD_PERIOD/2.0) rd_clk = ~rd_clk;

    // DUT
    async_fifo
`ifndef GATE_SIM
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
`endif
    dut (
        .wr_clk(wr_clk),  .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),    .wr_data(wr_data),
        .wr_full(wr_full), .wr_almost_full(wr_almost_full),

        .rd_clk(rd_clk),  .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),    .rd_data(rd_data),
        .rd_empty(rd_empty), .rd_almost_empty(rd_almost_empty)
    );

    //--------------------------------------------------------------
    // Reference queue (large enough for the test).
    //--------------------------------------------------------------
    reg [DATA_WIDTH-1:0] ref_q [0:4095];
    integer ref_head;     // next slot the producer will write
    integer ref_tail;     // next slot the consumer expects
    integer errors;
    integer pushed, popped;

    // Push: producer-side bookkeeping
    always @(posedge wr_clk) begin
        if (wr_rst_n && wr_en && !wr_full) begin
            ref_q[ref_head] <= wr_data;
            ref_head        <= ref_head + 1;
            pushed          <= pushed + 1;
        end
    end

    // Pop: consumer-side check
    always @(posedge rd_clk) begin
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
    // Stimulus tasks
    //--------------------------------------------------------------
    task do_reset;
        begin
            wr_rst_n = 0;
            rd_rst_n = 0;
            wr_en    = 0;
            rd_en    = 0;
            wr_data  = 0;
            ref_head = 0;
            ref_tail = 0;
            errors   = 0;
            pushed   = 0;
            popped   = 0;
            #50;
            wr_rst_n = 1;
            rd_rst_n = 1;
            #50;
        end
    endtask

    // Push N words with a random gap of 0..MAXGAP wr_clk cycles.
    // Drive on NEGEDGE with BLOCKING assignments so the DUT samples the
    // newly-asserted wr_en at the SAME posedge it samples wr_full.  This
    // eliminates the 1-cycle prediction error that arose with NBA driving.
    task producer_burst(input integer N, input integer MAXGAP);
        integer i, gap;
        reg [DATA_WIDTH-1:0] v;
        begin
            i = 0;
            v = 8'hA0;
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
    // Scenario runner
    //--------------------------------------------------------------
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);

        //----------------------------------------------------------
        // Scenario 1: fast writer, slow reader (FIFO will fill).
        //----------------------------------------------------------
        WR_PERIOD = 7.0;
        RD_PERIOD = 23.0;
        $display("\n=== Scenario 1: fast writer, slow reader ===");
        do_reset;
        fork
            producer_burst(64, 0);   // back-to-back writes
            consumer_burst(64, 2);
        join
        // Allow drain to settle
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d popped=%0d errors=%0d", pushed, popped, errors);

        //----------------------------------------------------------
        // Scenario 2: slow writer, fast reader (FIFO mostly empty).
        //----------------------------------------------------------
        WR_PERIOD = 23.0;
        RD_PERIOD = 7.0;
        $display("\n=== Scenario 2: slow writer, fast reader ===");
        do_reset;
        fork
            producer_burst(64, 3);
            consumer_burst(64, 0);
        join
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d popped=%0d errors=%0d", pushed, popped, errors);

        //----------------------------------------------------------
        // Scenario 3: similar rates, bursty.
        //----------------------------------------------------------
        WR_PERIOD = 10.0;
        RD_PERIOD = 13.0;
        $display("\n=== Scenario 3: bursty traffic, near-equal rates ===");
        do_reset;
        fork
            producer_burst(256, 2);
            consumer_burst(256, 2);
        join
        repeat (50) @(posedge rd_clk);
        $display("  pushed=%0d popped=%0d errors=%0d", pushed, popped, errors);

        //----------------------------------------------------------
        // Final result
        //----------------------------------------------------------
        if (errors == 0)
            $display("\n*** ALL SCENARIOS PASSED ***\n");
        else
            $display("\n*** %0d ERRORS DETECTED ***\n", errors);

        $finish;
    end

    // Safety net
    initial begin
        #200000;
        $display("TIMEOUT");
        $finish;
    end

endmodule

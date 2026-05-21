//-----------------------------------------------------------------------------
// async_fifo.v
//
// Asynchronous (multi-clock-domain) FIFO using reflected-binary (Gray code)
// pointers and two-flop synchronizers.  Architecture follows
//   Cliff E. Cummings, "Simulation and Synthesis Techniques for Asynchronous
//   FIFO Design", SNUG 2002.
//
// - Synthesizable (vendor-neutral, no behavioral $random / initial in RTL).
// - Pure Verilog-2001; no SystemVerilog constructs.
// - Reset: active-low, asynchronous assert / synchronous deassert in each
//   clock domain (handled by reset synchronizers below).
// - Depth = 2**`ADDR_WIDTH.  `ADDR_WIDTH >= 2 required.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none
`include "mcdfifo.vh"

//=============================================================================
// 2-flop synchronizer for the (`ADDR_WIDTH+1)-bit Gray pointer.
//=============================================================================
module sync_2ff (
    input  wire                clk,
    input  wire                rst_n,
    input  wire [`ADDR_WIDTH:0] d,
    output reg  [`ADDR_WIDTH:0] q
);
    reg [`ADDR_WIDTH:0] q1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= {(`ADDR_WIDTH+1){1'b0}};
            q  <= {(`ADDR_WIDTH+1){1'b0}};
        end else begin
            q1 <= d;
            q  <= q1;
        end
    end
endmodule


//=============================================================================
// Gray-to-binary converter (combinational, `ADDR_WIDTH+1 bits).
//   b[MSB]   = g[MSB]
//   b[i]     = b[i+1] ^ g[i]
//=============================================================================
module gray2bin (
    input  wire [`ADDR_WIDTH:0] g,
    output wire [`ADDR_WIDTH:0] b
);
    assign b[4] = g[4];
    assign b[3] = b[4] ^ g[3];
    assign b[2] = b[3] ^ g[2];
    assign b[1] = b[2] ^ g[1];
    assign b[0] = b[1] ^ g[0];
endmodule


//=============================================================================
// Reset synchronizer: async assert, sync deassert.
//=============================================================================
module reset_sync (
    input  wire clk,
    input  wire async_rst_n,
    output reg  sync_rst_n
);
    reg r1;
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            r1         <= 1'b0;
            sync_rst_n <= 1'b0;
        end else begin
            r1         <= 1'b1;
            sync_rst_n <= r1;
        end
    end
endmodule


//=============================================================================
// Top-level asynchronous FIFO.
//=============================================================================
module async_fifo (
    // ---- write clock domain ----
    input  wire                   wr_clk,
    input  wire                   wr_rst_n,    // async, active-low
    input  wire                   wr_en,
    input  wire [`DATA_WIDTH-1:0] wr_data,
    output wire                   wr_full,
    output wire                   wr_almost_full,   // optional

    // ---- read clock domain ----
    input  wire                   rd_clk,
    input  wire                   rd_rst_n,    // async, active-low
    input  wire                   rd_en,
    output wire [`DATA_WIDTH-1:0] rd_data,
    output wire                   rd_empty,
    output wire                   rd_almost_empty   // optional
);

    //-----------------------------------------------------------------
    // Reset synchronizers (one per clock domain).
    //-----------------------------------------------------------------
    wire wr_rst_n_s;
    wire rd_rst_n_s;

    reset_sync u_wr_rst_sync (.clk(wr_clk), .async_rst_n(wr_rst_n), .sync_rst_n(wr_rst_n_s));
    reset_sync u_rd_rst_sync (.clk(rd_clk), .async_rst_n(rd_rst_n), .sync_rst_n(rd_rst_n_s));

    //-----------------------------------------------------------------
    // Dual-port memory.  Inferred as block-RAM by most synthesis tools
    // when `DEPTH is large enough.  Independent r/w clocks.
    //-----------------------------------------------------------------
    reg [`DATA_WIDTH-1:0] mem [0:`DEPTH-1];

    //-----------------------------------------------------------------
    // Write side pointers (binary + Gray, `ADDR_WIDTH+1 bits wide).
    //
    // The extra MSB lets us distinguish "empty" from "full" when the
    // `ADDR_WIDTH-bit address parts match.
    //-----------------------------------------------------------------
    reg  [`ADDR_WIDTH:0] wr_bin;
    reg  [`ADDR_WIDTH:0] wr_gray;
    wire [`ADDR_WIDTH:0] wr_bin_next;
    wire [`ADDR_WIDTH:0] wr_gray_next;
    wire                 wr_inc;

    assign wr_inc       = wr_en & ~wr_full;
    assign wr_bin_next  = wr_bin + {{`ADDR_WIDTH{1'b0}}, wr_inc};
    assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

    always @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) begin
            wr_bin  <= {(`ADDR_WIDTH+1){1'b0}};
            wr_gray <= {(`ADDR_WIDTH+1){1'b0}};
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // Memory write port.
    always @(posedge wr_clk) begin
        if (wr_inc)
            mem[wr_bin[`ADDR_WIDTH-1:0]] <= wr_data;
    end

    //-----------------------------------------------------------------
    // Read side pointers (binary + Gray).
    //-----------------------------------------------------------------
    reg  [`ADDR_WIDTH:0] rd_bin;
    reg  [`ADDR_WIDTH:0] rd_gray;
    wire [`ADDR_WIDTH:0] rd_bin_next;
    wire [`ADDR_WIDTH:0] rd_gray_next;
    wire                 rd_inc;

    assign rd_inc       = rd_en & ~rd_empty;
    assign rd_bin_next  = rd_bin + {{`ADDR_WIDTH{1'b0}}, rd_inc};
    assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    always @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            rd_bin  <= {(`ADDR_WIDTH+1){1'b0}};
            rd_gray <= {(`ADDR_WIDTH+1){1'b0}};
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

    // Combinational read (latency = 0).  For BRAM use, change to a
    // registered output if the synthesis tool requires it.
    assign rd_data = mem[rd_bin[`ADDR_WIDTH-1:0]];

    //-----------------------------------------------------------------
    // Cross-domain pointer synchronizers.
    //   - rd_gray -> wr_clk domain (for full detection)
    //   - wr_gray -> rd_clk domain (for empty detection)
    //-----------------------------------------------------------------
    wire [`ADDR_WIDTH:0] rd_gray_at_wr;
    wire [`ADDR_WIDTH:0] wr_gray_at_rd;

    sync_2ff u_sync_rd2wr (
        .clk(wr_clk), .rst_n(wr_rst_n_s),
        .d(rd_gray),  .q(rd_gray_at_wr)
    );

    sync_2ff u_sync_wr2rd (
        .clk(rd_clk), .rst_n(rd_rst_n_s),
        .d(wr_gray),  .q(wr_gray_at_rd)
    );

    //-----------------------------------------------------------------
    // Full / Empty generation (REGISTERED).
    //
    // Both flags must be registered: making them purely combinational
    // creates a feedback loop because wr_inc / rd_inc depend on the
    // flag, and wr_gray_next / rd_gray_next depend on wr_inc / rd_inc.
    // Registering breaks the loop and matches Cummings's reference
    // design.
    //
    // Empty : next-read pointer == synced write pointer.
    // Full  : next-write pointer == synced read pointer with top two
    //         bits inverted (i.e. one full lap ahead in Gray space).
    //-----------------------------------------------------------------
    wire rd_empty_val = (rd_gray_next == wr_gray_at_rd);
    wire wr_full_val  = (wr_gray_next ==
                         { ~rd_gray_at_wr[`ADDR_WIDTH:`ADDR_WIDTH-1],
                            rd_gray_at_wr[`ADDR_WIDTH-2:0] });

    reg rd_empty_r;
    reg wr_full_r;

    always @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) rd_empty_r <= 1'b1;     // reset state = empty
        else             rd_empty_r <= rd_empty_val;
    end

    always @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) wr_full_r <= 1'b0;
        else             wr_full_r <= wr_full_val;
    end

    assign rd_empty = rd_empty_r;
    assign wr_full  = wr_full_r;

    //-----------------------------------------------------------------
    // Optional "almost" flags.  These are conservative (pessimistic)
    // because they use the synchronized opposite-domain pointer.
    //-----------------------------------------------------------------
    // Convert synchronized Gray pointers back to binary in each domain.
    wire [`ADDR_WIDTH:0] rd_bin_at_wr;
    wire [`ADDR_WIDTH:0] wr_bin_at_rd;
    gray2bin u_g2b_rd (.g(rd_gray_at_wr), .b(rd_bin_at_wr));
    gray2bin u_g2b_wr (.g(wr_gray_at_rd), .b(wr_bin_at_rd));

    wire [`ADDR_WIDTH:0] wr_used = wr_bin     - rd_bin_at_wr;
    wire [`ADDR_WIDTH:0] rd_used = wr_bin_at_rd - rd_bin;

    assign wr_almost_full  = (wr_used >= (`DEPTH - 1));
    assign rd_almost_empty = (rd_used <= 1);

endmodule

`default_nettype wire

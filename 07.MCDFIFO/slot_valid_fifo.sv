//-----------------------------------------------------------------------------
// slot_valid_fifo.sv
//
// Asynchronous (multi-clock-domain) FIFO using per-slot toggle (phase) flags.
//
// Architecture:
//   - `DEPTH = 2**`ADDR_WIDTH cells.
//   - Each cell i has:
//       mem[i]      : `DATA_WIDTH-bit storage
//       wr_phase[i] : 1-bit toggle, owned (written) only by wr_clk domain
//       rd_phase[i] : 1-bit toggle, owned (written) only by rd_clk domain
//   - "Cell has new data" when wr_phase[i] != rd_phase[i] (in the consumer's
//     view, via a 2-FF synchronizer).
//   - "Cell is empty"     when wr_phase[i] == rd_phase[i].
//
// Why phase bits instead of set / async-reset valid flags?
//   - Each FF is written only by its owning clock; the other domain only
//     READS it via a proper 2-FF synchronizer.  This avoids the
//     cross-domain SR-latch construct that the original "set valid HIGH /
//     async-reset valid LOW" idea would have produced.
//   - Data bus itself never crosses clock domains "live": by the time the
//     reader observes wr_phase[i] toggle (>= 2 rd_clk later), mem[i] has
//     been stable for at least 2 rd_clk cycles.
//
// Trade-off vs. Gray-code FIFO:
//   - Same steady-state throughput (1 word / wr_clk) as long as
//     `DEPTH * wr_period >> 5 cycle round-trip latency.
//   - Hardware grows O(`DEPTH) in FFs/synchronizers, not O(log `DEPTH).
//   - For small `DEPTH (~2..4) the round-trip latency limits throughput.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none
`include "mcdfifo.svh"

module slot_valid_fifo (
    // ---- write clock domain ----
    input  logic                   wr_clk,
    input  logic                   wr_rst_n,    // async assert, sync deassert
    input  logic                   wr_en,
    input  logic [`DATA_WIDTH-1:0] wr_data,
    output logic                   wr_full,

    // ---- read clock domain ----
    input  logic                   rd_clk,
    input  logic                   rd_rst_n,    // async assert, sync deassert
    input  logic                   rd_en,
    output logic [`DATA_WIDTH-1:0] rd_data,
    output logic                   rd_empty
);
    //-----------------------------------------------------------------
    // Per-domain reset synchronizers
    //-----------------------------------------------------------------
    logic wr_rst_r1, wr_rst_n_s;
    logic rd_rst_r1, rd_rst_n_s;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_rst_r1  <= 1'b0;
            wr_rst_n_s <= 1'b0;
        end else begin
            wr_rst_r1  <= 1'b1;
            wr_rst_n_s <= wr_rst_r1;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_rst_r1  <= 1'b0;
            rd_rst_n_s <= 1'b0;
        end else begin
            rd_rst_r1  <= 1'b1;
            rd_rst_n_s <= rd_rst_r1;
        end
    end

    //-----------------------------------------------------------------
    // Storage and per-slot phase bits
    //-----------------------------------------------------------------
    logic [`DATA_WIDTH-1:0] mem      [0:`DEPTH-1];
    logic                   wr_phase [0:`DEPTH-1];   // written only in wr_clk
    logic                   rd_phase [0:`DEPTH-1];   // written only in rd_clk

    //-----------------------------------------------------------------
    // Per-slot 2-FF synchronizers
    //   wr_phase[*] -> rd_clk domain (consumer side sees "new data ready")
    //   rd_phase[*] -> wr_clk domain (producer side sees "slot freed")
    //-----------------------------------------------------------------
    logic wr_phase_at_rd_1 [0:`DEPTH-1];
    logic wr_phase_at_rd_2 [0:`DEPTH-1];
    logic rd_phase_at_wr_1 [0:`DEPTH-1];
    logic rd_phase_at_wr_2 [0:`DEPTH-1];

    // wr_phase -> rd_clk
    always_ff @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            for (int i = 0; i < `DEPTH; i++) begin
                wr_phase_at_rd_1[i] <= 1'b0;
                wr_phase_at_rd_2[i] <= 1'b0;
            end
        end else begin
            for (int i = 0; i < `DEPTH; i++) begin
                wr_phase_at_rd_1[i] <= wr_phase[i];
                wr_phase_at_rd_2[i] <= wr_phase_at_rd_1[i];
            end
        end
    end

    // rd_phase -> wr_clk
    always_ff @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) begin
            for (int i = 0; i < `DEPTH; i++) begin
                rd_phase_at_wr_1[i] <= 1'b0;
                rd_phase_at_wr_2[i] <= 1'b0;
            end
        end else begin
            for (int i = 0; i < `DEPTH; i++) begin
                rd_phase_at_wr_1[i] <= rd_phase[i];
                rd_phase_at_wr_2[i] <= rd_phase_at_wr_1[i];
            end
        end
    end

    //-----------------------------------------------------------------
    // Write side: pointer + phase toggle + memory write
    //   FULL when wr_phase[wr_ptr] != (synced) rd_phase[wr_ptr]
    //   i.e., the slot still holds data the reader hasn't acked.
    //-----------------------------------------------------------------
    logic [`ADDR_WIDTH-1:0] wr_ptr;
    assign wr_full = (wr_phase[wr_ptr] != rd_phase_at_wr_2[wr_ptr]);

    always_ff @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) begin
            wr_ptr <= {`ADDR_WIDTH{1'b0}};
            for (int j = 0; j < `DEPTH; j++) begin
                wr_phase[j] <= 1'b0;
            end
        end else if (wr_en && !wr_full) begin
            mem[wr_ptr]      <= wr_data;
            wr_phase[wr_ptr] <= ~wr_phase[wr_ptr];
            wr_ptr           <= wr_ptr + 1'b1;
        end
    end

    //-----------------------------------------------------------------
    // Read side: pointer + phase toggle + combinational data read
    //   EMPTY when (synced) wr_phase[rd_ptr] == rd_phase[rd_ptr]
    //   i.e., this slot's version has already been consumed.
    //-----------------------------------------------------------------
    logic [`ADDR_WIDTH-1:0] rd_ptr;
    assign rd_empty = (wr_phase_at_rd_2[rd_ptr] == rd_phase[rd_ptr]);
    assign rd_data  = mem[rd_ptr];

    always_ff @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            rd_ptr <= {`ADDR_WIDTH{1'b0}};
            for (int j = 0; j < `DEPTH; j++) begin
                rd_phase[j] <= 1'b0;
            end
        end else if (rd_en && !rd_empty) begin
            rd_phase[rd_ptr] <= ~rd_phase[rd_ptr];
            rd_ptr           <= rd_ptr + 1'b1;
        end
    end

endmodule

`default_nettype wire

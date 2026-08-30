// SPDX-License-Identifier: GPL-3.0-or-later
`timescale 1ns/1ps
// Small dual-clock elastic FIFO for the fixed-rate GMII/PCS crossings.
// Binary pointers address storage; Gray-coded pointers are the only values
// synchronized between clock domains.
module open_eth_async_fifo #(
    parameter WIDTH = 10,
    parameter ADDR_WIDTH = 5
) (
    input  wire                  wr_clk,
    input  wire                  wr_resetn,
    input  wire [WIDTH-1:0]      wr_data,
    input  wire                  wr_en,
    output wire                  wr_full,
    output wire [ADDR_WIDTH:0]   wr_level,
    input  wire                  rd_clk,
    input  wire                  rd_resetn,
    output wire [WIDTH-1:0]      rd_data,
    input  wire                  rd_en,
    output wire                  rd_empty,
    output wire [ADDR_WIDTH:0]   rd_level
);

localparam DEPTH = 1 << ADDR_WIDTH;
reg [WIDTH-1:0] memory [0:DEPTH-1];
reg [ADDR_WIDTH:0] wr_binary;
reg [ADDR_WIDTH:0] wr_gray;
reg [ADDR_WIDTH:0] rd_binary;
reg [ADDR_WIDTH:0] rd_gray;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rd_gray_wr_meta;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rd_gray_wr_sync;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wr_gray_rd_meta;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wr_gray_rd_sync;

function automatic [ADDR_WIDTH:0] gray_to_binary;
    input [ADDR_WIDTH:0] gray;
    integer index;
    begin
        gray_to_binary[ADDR_WIDTH] = gray[ADDR_WIDTH];
        for (index = ADDR_WIDTH-1; index >= 0; index = index - 1)
            gray_to_binary[index] = gray_to_binary[index+1] ^ gray[index];
    end
endfunction

wire [ADDR_WIDTH:0] wr_binary_increment = wr_binary + 1'b1;
wire [ADDR_WIDTH:0] wr_gray_increment =
    (wr_binary_increment >> 1) ^ wr_binary_increment;
wire [ADDR_WIDTH:0] wr_binary_next = wr_binary + (wr_en && !wr_full);
wire [ADDR_WIDTH:0] wr_gray_next =
    (wr_binary_next >> 1) ^ wr_binary_next;
wire [ADDR_WIDTH:0] rd_binary_next = rd_binary + (rd_en && !rd_empty);
wire [ADDR_WIDTH:0] rd_gray_next =
    (rd_binary_next >> 1) ^ rd_binary_next;

assign wr_full = wr_gray_increment ==
    {~rd_gray_wr_sync[ADDR_WIDTH:ADDR_WIDTH-1],
     rd_gray_wr_sync[ADDR_WIDTH-2:0]};
assign rd_empty = rd_gray == wr_gray_rd_sync;
assign wr_level = wr_binary - gray_to_binary(rd_gray_wr_sync);
assign rd_level = gray_to_binary(wr_gray_rd_sync) - rd_binary;
assign rd_data = memory[rd_binary[ADDR_WIDTH-1:0]];

always @(posedge wr_clk) begin
    if (!wr_resetn) begin
        wr_binary <= 0;
        wr_gray <= 0;
        rd_gray_wr_meta <= 0;
        rd_gray_wr_sync <= 0;
    end else begin
        rd_gray_wr_meta <= rd_gray;
        rd_gray_wr_sync <= rd_gray_wr_meta;
        if (wr_en && !wr_full)
            memory[wr_binary[ADDR_WIDTH-1:0]] <= wr_data;
        wr_binary <= wr_binary_next;
        wr_gray <= wr_gray_next;
    end
end

always @(posedge rd_clk) begin
    if (!rd_resetn) begin
        rd_binary <= 0;
        rd_gray <= 0;
        wr_gray_rd_meta <= 0;
        wr_gray_rd_sync <= 0;
    end else begin
        wr_gray_rd_meta <= wr_gray;
        wr_gray_rd_sync <= wr_gray_rd_meta;
        rd_binary <= rd_binary_next;
        rd_gray <= rd_gray_next;
    end
end

endmodule

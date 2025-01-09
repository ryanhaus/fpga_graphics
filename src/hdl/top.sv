/* verilator lint_off WIDTHEXPAND */
`define DISPLAY_WIDTH 320
`define DISPLAY_HEIGHT 240
`define VRAM_SIZE 256
`define VRAM_DATA_BITS $bits(triangle)
`define VRAM_ADDR_BITS $clog2(`VRAM_SIZE)

`include "triangle.sv"

module top(
	input rst,

	// signals for display output
	input display_out_clk,
	output [15:0] pixel_out,

	// signals for internal logic (generating the video)
	input logic_clk,
	input [$clog2(`DISPLAY_WIDTH)-1 : 0] x_in,
	input [$clog2(`DISPLAY_HEIGHT)-1 : 0] y_in,

	// signals for updating the VRAM
	input vram_wr_clk,
	input vram_wr_en,
	input [`VRAM_ADDR_BITS-1 : 0] vram_wr_addr,
	input [`VRAM_DATA_BITS-1 : 0] vram_wr_in
);

	// framebuffer memory (direct video output)
	bit framebuffer_wr_en;
	bit [framebuffer_ram.ADDR_BITS-1 : 0] framebuffer_wr_addr;
	bit [framebuffer_ram.DATA_WIDTH-1 : 0] framebuffer_wr_in;

	dpram #(.DATA_WIDTH(16), .DATA_N(320 * 240)) framebuffer_ram (
		.rst(rst),
		.rd_clk(display_out_clk),
		.rd_addr(x_in + `DISPLAY_WIDTH * y_in),
		.rd_out(pixel_out),
		.wr_clk(logic_clk),
		.wr_en(framebuffer_wr_en),
		.wr_addr(framebuffer_wr_addr),
		.wr_in(framebuffer_wr_in)
	);

	// video memory (contains triangles to be rendered)
	bit [`VRAM_ADDR_BITS-1 : 0] vram_rd_addr;
	bit [`VRAM_DATA_BITS-1 : 0] vram_rd_data;

	dpram #(.DATA_WIDTH(`VRAM_DATA_BITS), .DATA_N(`VRAM_SIZE)) video_ram (
		.rst(rst),
		.rd_clk(logic_clk),
		.rd_addr(vram_rd_addr),
		.rd_out(vram_rd_data),
		.wr_clk(vram_wr_clk),
		.wr_en(vram_wr_en),
		.wr_addr(vram_wr_addr),
		.wr_in(vram_wr_in)
	);

	// generates video based on VRAM and writes to framebuffer
	video_generator #(
		.DISPLAY_WIDTH(`DISPLAY_WIDTH),
		.DISPLAY_HEIGHT(`DISPLAY_HEIGHT),
		.VRAM_DATA_BITS(`VRAM_DATA_BITS),
		.VRAM_SIZE(`VRAM_SIZE)
	) videogen (
		.rst(rst),
		.clk(~logic_clk),
		.vram_rd_addr(vram_rd_addr),
		.vram_rd_data(vram_rd_data),
		.framebuffer_wr_en(framebuffer_wr_en),
		.framebuffer_wr_addr(framebuffer_wr_addr),
		.framebuffer_data(framebuffer_wr_in)
	);

endmodule

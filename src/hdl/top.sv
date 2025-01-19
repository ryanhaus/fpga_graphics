/* verilator lint_off WIDTHEXPAND */
`define DISPLAY_WIDTH 320
`define DISPLAY_HEIGHT 240
`define VRAM_SIZE 2**12
`define VRAM_DATA_BITS $bits(triangle)
`define VRAM_ADDR_BITS $clog2(`VRAM_SIZE)
`define ZBUFFER_DATA_BITS $bits(point_val_t)

`include "triangle.sv"

module top(
	input rst,

	// signals for display output
	input display_out_clk,
	output [15:0] pixel_out,

	// signals for internal logic (generating the video)
	input logic_clk,
	input frame_start,
	output frame_done,
	input [$clog2(`DISPLAY_WIDTH)-1 : 0] x_in,
	input [$clog2(`DISPLAY_HEIGHT)-1 : 0] y_in,

	// signals for updating the VRAM
	input vram_wr_clk,
	input vram_wr_en,
	input [`VRAM_ADDR_BITS-1 : 0] vram_wr_addr,
	input padded_triangle vram_wr_in_padded
);

	// unpad the input
	triangle vram_wr_in;

	always_comb begin
		vram_wr_in = unpad_tri(vram_wr_in_padded);
	end

	// framebuffer memory (direct video output)
	bit framebuffer_wr_en;
	bit framebuffer_rst;
	bit [framebuffer_ram.ADDR_BITS-1 : 0] framebuffer_wr_addr;
	bit [framebuffer_ram.DATA_WIDTH-1 : 0] framebuffer_wr_in;

	dpram #(.DATA_WIDTH(16), .DATA_N(`DISPLAY_WIDTH * `DISPLAY_HEIGHT)) framebuffer_ram (
		.rst(rst | framebuffer_rst),
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

	// z buffer (holds z value of every pixel for comparision)
	bit [zbuffer_ram.ADDR_BITS-1 : 0] zbuffer_rd_addr;
	bit [zbuffer_ram.DATA_WIDTH-1 : 0] zbuffer_rd_out;
	bit [zbuffer_ram.ADDR_BITS-1 : 0] zbuffer_wr_addr;
	bit [zbuffer_ram.DATA_WIDTH-1 : 0] zbuffer_wr_in;
	bit zbuffer_wr_en;
	
	dpram #(
		.DATA_WIDTH(`ZBUFFER_DATA_BITS),
		.DATA_N(`DISPLAY_WIDTH * `DISPLAY_HEIGHT),
		.RST_VAL(20'hFFFFF)
	) zbuffer_ram (
		.rst(rst | framebuffer_rst),
		.rd_clk(logic_clk),
		.rd_addr(zbuffer_rd_addr),
		.rd_out(zbuffer_rd_out),
		.wr_clk(logic_clk),
		.wr_en(zbuffer_wr_en),
		.wr_addr(zbuffer_wr_addr),
		.wr_in(zbuffer_wr_in)
	);

	// generates video based on VRAM and writes to framebuffer and zbuffer
	video_generator #(
		.DISPLAY_WIDTH(`DISPLAY_WIDTH),
		.DISPLAY_HEIGHT(`DISPLAY_HEIGHT),
		.VRAM_DATA_BITS(`VRAM_DATA_BITS),
		.VRAM_SIZE(`VRAM_SIZE)
	) videogen (
		.rst(rst),
		.clk(~logic_clk),
		.frame_start(frame_start),
		.frame_done(frame_done),
		.vram_rd_addr(vram_rd_addr),
		.vram_rd_data(vram_rd_data),
		.framebuffer_wr_en(framebuffer_wr_en),
		.framebuffer_rst(framebuffer_rst),
		.framebuffer_wr_addr(framebuffer_wr_addr),
		.framebuffer_data(framebuffer_wr_in),
		.zbuffer_rd_addr(zbuffer_rd_addr),
		.zbuffer_rd_data(zbuffer_rd_out),
		.zbuffer_wr_addr(zbuffer_wr_addr),
		.zbuffer_wr_data(zbuffer_wr_in),
		.zbuffer_wr_en(zbuffer_wr_en)
	);

endmodule

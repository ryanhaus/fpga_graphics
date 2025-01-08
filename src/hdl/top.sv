/* verilator lint_off WIDTHEXPAND */
`define DISPLAY_WIDTH 320
`define DISPLAY_HEIGHT 240

module top(
	input rst,

	input display_out_clk,
	input logic_clk,

	input [$clog2(`DISPLAY_WIDTH)-1 : 0] x_in,
	input [$clog2(`DISPLAY_HEIGHT)-1 : 0] y_in,
	
	output [15:0] pixel_out
);
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

	video_generator #(.DISPLAY_WIDTH(`DISPLAY_WIDTH), .DISPLAY_HEIGHT(`DISPLAY_HEIGHT)) videogen (
		.rst(rst),
		.clk(~logic_clk),
		.framebuffer_wr_en(framebuffer_wr_en),
		.framebuffer_wr_addr(framebuffer_wr_addr),
		.framebuffer_data(framebuffer_wr_in)
	);

endmodule

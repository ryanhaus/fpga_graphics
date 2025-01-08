/* verilator lint_off WIDTHEXPAND */
`define DISPLAY_WIDTH 320
`define DISPLAY_HEIGHT 240

module top(
	input rst,

	input rd_clk,
	input wr_clk,

	input wr_en,

	input [15:0] wr_in,

	input [$clog2(`DISPLAY_WIDTH)-1 : 0] x_in,
	input [$clog2(`DISPLAY_HEIGHT)-1 : 0] y_in,
	
	output [15:0] pixel_out
);

	dpram #(.DATA_WIDTH(16), .DATA_N(320 * 240)) framebuffer_ram (
		.rst(rst),
		.rd_clk(rd_clk),
		.rd_addr(x_in + `DISPLAY_WIDTH * y_in),
		.rd_out(pixel_out),
		.wr_clk(wr_clk),
		.wr_en(wr_en),
		.wr_addr(x_in + `DISPLAY_WIDTH * y_in),
		.wr_in(wr_in)
	);

endmodule

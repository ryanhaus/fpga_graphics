`define DISPLAY_WIDTH 320
`define DISPLAY_HEIGHT 240

module top(
	input clk,
	input rst,

	input [$clog2(`DISPLAY_WIDTH)-1 : 0] x_in,
	input [$clog2(`DISPLAY_HEIGHT)-1 : 0] y_in,
	output reg [15:0] pixel_out
);

	reg [4:0] brightness = 5'b0;

	always @(posedge clk) begin
		/* verilator lint_off WIDTHTRUNC */
		brightness = x_in + y_in;
		pixel_out = {brightness, brightness, 1'b0, brightness};
	end

endmodule

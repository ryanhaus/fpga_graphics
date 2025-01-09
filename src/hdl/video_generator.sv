/* verilator lint_off WIDTHCONCAT */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
module video_generator #(
	parameter DISPLAY_WIDTH = 100,
	parameter DISPLAY_HEIGHT = 100,
	parameter VRAM_DATA_BITS = 8,
	parameter VRAM_SIZE = 256,
	parameter VRAM_ADDR_BITS = $clog2(VRAM_SIZE),
	parameter FRAMEBUFFER_DATA_BITS = 16,
	parameter FRAMEBUFFER_SIZE = DISPLAY_WIDTH * DISPLAY_HEIGHT,
	parameter FRAMEBUFFER_ADDR_BITS = $clog2(FRAMEBUFFER_SIZE)
) (
	input rst,
	input clk,

	output bit [VRAM_ADDR_BITS-1 : 0] vram_rd_addr,
	input bit [VRAM_DATA_BITS-1 : 0] vram_rd_data,

	output bit framebuffer_wr_en,
	output bit [FRAMEBUFFER_ADDR_BITS-1 : 0] framebuffer_wr_addr,
	output bit [FRAMEBUFFER_DATA_BITS-1 : 0] framebuffer_data
);

	// handle going through each pixel in the display
	bit counter_enable;
	integer display_x;
	integer display_y;
	bit counter_done;

	counter_2d #(.WIDTH(DISPLAY_WIDTH), .HEIGHT(DISPLAY_HEIGHT)) display_counter (
		.rst(rst),
		.clk(~clk),
		.enable(counter_enable),
		.out_x(display_x),
		.out_y(display_y),
		.out_total(framebuffer_wr_addr),
		.done(counter_done)
	);

	// test if the current point is in the current triangle
	// if so, write to the framebuffer
	tri_point_tester tri_tester (
		.in_point({ display_x, display_y }),
		.in_tri(vram_rd_data),
		.point_in_tri(framebuffer_wr_en)
	);

	bit [4:0] r = 5'h1F;
	bit [5:0] g = 'b0;
	bit [4:0] b = 'b0;

	// move onto the next triangle in memory once finished
	always_ff @(posedge clk) begin
		if (rst) begin
			counter_enable = 'b0;
			framebuffer_data = 'b0;
		end
		else begin
			counter_enable = 'b1;
			framebuffer_data = { r, g, b };

			if (counter_done) begin
				vram_rd_addr = vram_rd_addr + 'b1;
			end
		end
	end

endmodule

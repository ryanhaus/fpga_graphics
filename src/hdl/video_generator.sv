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

	// these are used to ensure that counting does not start until 1 full
	// clock cycle after a reset occurs
	bit clock_has_risen;
	bit clock_has_fallen;

	// handle going through each pixel in the display
	bit counter_enable;
	integer display_x;
	integer display_y;
	integer out_total;
	bit counter_done;

	counter_2d #(.WIDTH(DISPLAY_WIDTH), .HEIGHT(DISPLAY_HEIGHT)) display_counter (
		.rst(rst),
		.clk(~clk),
		.enable(counter_enable),
		.out_x(display_x),
		.out_y(display_y),
		.out_total(out_total),
		.done(counter_done)
	);

	// test if the current point is in the current triangle
	// if so, write to the framebuffer
	bit point_in_tri;

	tri_point_tester tri_tester (
		.in_point({ display_x, display_y }),
		.in_tri(vram_rd_data),
		.point_in_tri(point_in_tri)
	);

	bit [4:0] r = 5'h1F;
	bit [5:0] g = 'b0;
	bit [4:0] b = 'b0;

	always_ff @(posedge clk) begin
		if (rst) begin
			counter_enable = 'b0;
			clock_has_risen = 'b0;
			framebuffer_data = 'b0;
		end
		else begin
			clock_has_risen = 'b1;
			counter_enable = clock_has_risen && clock_has_fallen;
			framebuffer_data = { r, g, b };

			framebuffer_wr_addr = out_total;
			framebuffer_wr_en = point_in_tri;

			// move onto the next triangle in memory once finished
			if (counter_done) begin
				vram_rd_addr = vram_rd_addr + 'b1;
			end
		end
	end

	always_ff @(negedge clk) begin
		if (rst) begin
			clock_has_fallen = 'b0;
		end
		else begin
			clock_has_fallen = 'b1;
		end
	end

endmodule

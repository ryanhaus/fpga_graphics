/* verilator lint_off WIDTHCONCAT */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

typedef enum {
	LOAD_TRIANGLE,
	UPDATE_COUNTER_RANGE,
	TEST_TRIANGLE
} video_gen_state;

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

	triangle current_tri;

	// handle going through each pixel in the display
	bit counter_rst;
	integer display_x;
	integer display_y;
	bit counter_done;

	integer counter_x_start;
	integer counter_y_start;
	integer counter_x_end;
	integer counter_y_end;

	counter_2d #(.WIDTH(DISPLAY_WIDTH), .HEIGHT(DISPLAY_HEIGHT)) display_counter (
		.rst(rst | counter_rst),
		.clk(~clk),
		.enable(1),
		.x_start(counter_x_start),
		.y_start(counter_y_start),
		.x_end(counter_x_end),
		.y_end(counter_y_end),
		.out_x(display_x),
		.out_y(display_y),
		.done(counter_done)
	);

	// test if the current point is in the current triangle
	// if so, write to the framebuffer
	bit point_in_tri;

	tri_point_tester tri_tester (
		.in_point({ display_x, display_y }),
		.in_tri(current_tri),
		.point_in_tri(point_in_tri)
	);

	// get the bounding box of the current triangle
	integer tri_bb_min_x;
	integer tri_bb_min_y;
	integer tri_bb_max_x;
	integer tri_bb_max_y;
	
	tri_bounding_box_gen #(
		.DISPLAY_WIDTH(DISPLAY_WIDTH),
		.DISPLAY_HEIGHT(DISPLAY_HEIGHT)
	) tri_bound_box_gen (
		.in_tri(current_tri),
		.min_x(tri_bb_min_x),
		.min_y(tri_bb_min_y),
		.max_x(tri_bb_max_x),
		.max_y(tri_bb_max_y)
	);

	// output color
	bit [4:0] r = 5'h1F;
	bit [5:0] g = 'b0;
	bit [4:0] b = 'b0;

	// state handler
	video_gen_state state;

	always_ff @(posedge clk) begin
		if (rst) begin
			state = LOAD_TRIANGLE;
			framebuffer_data = 'b0;
			framebuffer_wr_addr = 'b0;
			framebuffer_wr_en = 'b0;
			vram_rd_addr = 'b0;
			current_tri = 'b0;
		end
		else begin
			counter_rst = 'b0;
			framebuffer_data = 'b0;
			framebuffer_wr_en = 'b0;

			case (state)
				LOAD_TRIANGLE: begin
					// loads the triangle at vram_rd_addr into current_tri,
					// then increments vram_rd_addr
					current_tri = vram_rd_data;
					vram_rd_addr = vram_rd_addr + 1;
					state = UPDATE_COUNTER_RANGE;
				end

				UPDATE_COUNTER_RANGE: begin
					// updates the range of the counter_2d instance to match
					// the bounding box of the current triangle
					counter_x_start = tri_bb_min_x;
					counter_y_start = tri_bb_min_y;
					counter_x_end = tri_bb_max_x;
					counter_y_end = tri_bb_max_y;

					// also reset the counter
					counter_rst = 'b1;

					state = TEST_TRIANGLE;
				end

				TEST_TRIANGLE: begin
					// tests if the current point is in the triangle, if so,
					// then write some data to the framebuffer
					framebuffer_data = { r, g, b };
					framebuffer_wr_addr = display_x + DISPLAY_WIDTH * display_y;
					framebuffer_wr_en = point_in_tri;

					// move onto the next triangle in memory once finished
					if (counter_done) begin
						state = LOAD_TRIANGLE;
					end
				end

			endcase
		end
	end

endmodule

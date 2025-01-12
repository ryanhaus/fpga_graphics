/* verilator lint_off WIDTHCONCAT */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

typedef enum {
	WAIT_VRAM,
	LOAD_TRIANGLE,
	COMPUTE_TRANSFORMED_TRIANGLE,
	WAIT_FOR_TRANSFORMED_TRI_RESULT,
	COMPUTE_INVERSE_EDGE_FN,
	WAIT_FOR_INVERSE_EDGE_FN_RESULT,
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
	parameter FRAMEBUFFER_ADDR_BITS = $clog2(FRAMEBUFFER_SIZE),
	parameter Z_SCALER = 2**12
) (
	input rst,
	input clk,

	output bit [VRAM_ADDR_BITS-1 : 0] vram_rd_addr,
	input bit [VRAM_DATA_BITS-1 : 0] vram_rd_data,

	output bit framebuffer_wr_en,
	output bit [FRAMEBUFFER_ADDR_BITS-1 : 0] framebuffer_wr_addr,
	output bit [FRAMEBUFFER_DATA_BITS-1 : 0] framebuffer_data
);

	triangle current_tri; // current triangle, as read directly from VRAM
	int_triangle current_tri_int; // current triangle after integer transform
	int_point current_point_int; // current point (integer since represents a pixel)

	// handle going through each pixel in the display
	bit counter_rst;
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
		.out_x(current_point_int.x),
		.out_y(current_point_int.y),
		.done(counter_done)
	);

	// test if the current point is in the current triangle
	// if so, write to the framebuffer
	bit point_in_tri;

	tri_point_tester tri_tester (
		.in_point(current_point_int),
		.in_tri(current_tri_int),
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
		.in_tri(current_tri_int),
		.min_x(tri_bb_min_x),
		.min_y(tri_bb_min_y),
		.max_x(tri_bb_max_x),
		.max_y(tri_bb_max_y)
	);

	// calculate the 'weights' of each point of the triangle
	// note that weights are stored as fixed-point numbers with 1 integer bit
	// and 31 exponent bits
	integer signed tri_edge_fn;
	integer signed inverse_edge_fn;
	integer signed weight_a;
	integer signed weight_b;
	integer signed weight_c;

	tri_point_weight_calc weight_calc_inst (
		.in_tri(current_tri_int),
		.in_point(current_point_int),
		.tri_edge_fn(tri_edge_fn),
		.inverse_tri_edge_fn(inverse_edge_fn),
		.weight_a(weight_a),
		.weight_b(weight_b),
		.weight_c(weight_c)
	);

	// divider for computing the inverse edge function of the current triangle
	localparam DIV_BITS = 32;
	bit [DIV_BITS-1 : 0] div_numerator;
	bit [DIV_BITS-1 : 0] div_denominator;
	bit [DIV_BITS-1 : 0] div_quotient;
	bit [DIV_BITS-1 : 0] div_remainder;
	bit div_numerator_signed;
	bit div_start;
	bit div_busy;
	bit div_result_valid;

	divider #(.N_BITS(DIV_BITS)) divider_inst (
		.clk(~clk),
		.rst(rst),
		.numerator(div_numerator),
		.denominator(div_denominator),
		.numerator_signed(div_numerator_signed),
		.start(div_start),
		.busy(div_busy),
		.quotient(div_quotient),
		.remainder(div_remainder),
		.result_valid(div_result_valid)
	);

	// generates a color based on the three weight_* values
	color out_color;

	color_gen color_gen_inst (
		.in_tri(current_tri_int),
		.weight_a(weight_a),
		.weight_b(weight_b),
		.weight_c(weight_c),
		.out_col(out_color)
	);

	// used in the transformation calculation states
	integer trans_pt_i; // current point in the COMPUTE_TRANSFORMED_TRIANGLE state (i.e., a, b, or c)
	integer trans_pt_axis_i; // current axis in the COMPUTE_TRANSFORMED_TRIANGLE state (i.e., x or y)

	int_point tri_points[2:0];
	int_point trans_current_pt;

	integer signed pt_axes[1:0];
	integer trans_current_axis;

	integer signed trans_tri_pt_values[2:0][1:0];
	
	always_comb begin
		tri_points[0] = current_tri_int.a;
		tri_points[1] = current_tri_int.b;
		tri_points[2] = current_tri_int.c;
		trans_current_pt = tri_points[trans_pt_i];

		pt_axes[0] = trans_current_pt.x;
		pt_axes[1] = trans_current_pt.y;
		trans_current_axis = pt_axes[trans_pt_axis_i];
	end

	// state handler
	video_gen_state state;

	always_ff @(posedge clk) begin
		if (rst) begin
			state = WAIT_VRAM;
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
				WAIT_VRAM: begin
					// dummy stage to allow VRAM read to occur on first pass
					state = LOAD_TRIANGLE;
				end

				LOAD_TRIANGLE: begin
					// loads the triangle at vram_rd_addr into current_tri,
					// then increments vram_rd_addr
					current_tri = vram_rd_data;
					vram_rd_addr = vram_rd_addr + 1;
					trans_pt_i = 0;
					trans_pt_axis_i = 0;

					// also convert the triangle into its integer form, as it
					// now contains points that are fixed-point numbers
					current_tri_int.a.x = ($signed(current_tri.a.x) * DISPLAY_WIDTH) / 2**12;
					current_tri_int.a.y = ($signed(current_tri.a.y) * DISPLAY_HEIGHT) / 2**12;
					current_tri_int.a.z = ($signed(current_tri.a.z) * Z_SCALER) / 2**12;
					current_tri_int.a.col = current_tri.a.col;

					current_tri_int.b.x = ($signed(current_tri.b.x) * DISPLAY_WIDTH) / 2**12;
					current_tri_int.b.y = ($signed(current_tri.b.y) * DISPLAY_HEIGHT) / 2**12;
					current_tri_int.b.z = ($signed(current_tri.b.z) * Z_SCALER) / 2**12;
					current_tri_int.b.col = current_tri.b.col;

					current_tri_int.c.x = ($signed(current_tri.c.x) * DISPLAY_WIDTH) / 2**12;
					current_tri_int.c.y = ($signed(current_tri.c.y) * DISPLAY_HEIGHT) / 2**12;
					current_tri_int.c.z = ($signed(current_tri.c.z) * Z_SCALER) / 2**12;
					current_tri_int.c.col = current_tri.c.col;

					state = COMPUTE_TRANSFORMED_TRIANGLE;
				end
				
				COMPUTE_TRANSFORMED_TRIANGLE: begin
					// setup point transformation calculation
					div_numerator = trans_current_axis * Z_SCALER / 2;
					div_denominator = trans_current_pt.z;
					div_numerator_signed = 1;
					div_start = 1;

					state = WAIT_FOR_TRANSFORMED_TRI_RESULT;
				end

				WAIT_FOR_TRANSFORMED_TRI_RESULT: begin
					// once the start signal has been acknowledged it can be
					// set back to low to prevent the divider from looping
					if (div_busy) begin
						div_start = 0;
					end

					// once the result is valid, update values and figure
					// out where to go next
					if (div_result_valid) begin
						trans_tri_pt_values[trans_pt_i][trans_pt_axis_i] = div_quotient;
						// if done with current point
						if (trans_pt_axis_i == 1) begin
							// if done with current triangle
							if (trans_pt_i == 2) begin
								current_tri_int.a.x = trans_tri_pt_values[0][0] + DISPLAY_WIDTH / 2;
								current_tri_int.a.y = trans_tri_pt_values[0][1] + DISPLAY_HEIGHT / 2;
								current_tri_int.b.x = trans_tri_pt_values[1][0] + DISPLAY_WIDTH / 2;
								current_tri_int.b.y = trans_tri_pt_values[1][1] + DISPLAY_HEIGHT / 2;
								current_tri_int.c.x = trans_tri_pt_values[2][0] + DISPLAY_WIDTH / 2;
								current_tri_int.c.y = trans_tri_pt_values[2][1] + DISPLAY_HEIGHT / 2;

								state = COMPUTE_INVERSE_EDGE_FN;
							end
							else begin
								trans_pt_i = trans_pt_i + 1;
								trans_pt_axis_i = 0;
								state = COMPUTE_TRANSFORMED_TRIANGLE;
							end
						end
						else begin
							trans_pt_axis_i = trans_pt_axis_i + 1;
							state = COMPUTE_TRANSFORMED_TRIANGLE;
						end
					end
				end

				COMPUTE_INVERSE_EDGE_FN: begin
					// creates a fixed-point number with 1 integer bit and
					// the rest fractional bits
					div_numerator = 1 << (DIV_BITS - 1);
					div_denominator = tri_edge_fn;
					div_numerator_signed = 0;
					div_start = 1;

					state = WAIT_FOR_INVERSE_EDGE_FN_RESULT;
				end

				WAIT_FOR_INVERSE_EDGE_FN_RESULT: begin
					// once the start signal has been acknowledged it can be
					// set back to low to prevent the divider from looping
					if (div_busy) begin
						div_start = 0;
					end

					if (div_result_valid) begin
						inverse_edge_fn = div_quotient;
						state = UPDATE_COUNTER_RANGE;
					end
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
					framebuffer_data = out_color;
					framebuffer_wr_addr = current_point_int.x + DISPLAY_WIDTH * current_point_int.y;
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

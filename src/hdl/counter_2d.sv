// 2-dimensional counter
module counter_2d #(
	parameter WIDTH = 10, // width of the counter (how far X will go)
	parameter HEIGHT = 10, // height of the counter (how far Y will go)
	parameter TOTAL = WIDTH * HEIGHT, // number of states
	parameter X_BITS = $clog2(WIDTH), // number of bits needed to represent WIDTH values
	parameter Y_BITS = $clog2(HEIGHT), // number of bits needed to represent HEIGHT values
	parameter TOTAL_BITS = $clog2(TOTAL) // number of bits needed to represent the total number of states
) (
	input rst,
	input clk,
	input enable,

	input bit [X_BITS-1 : 0] x_start,
	input bit [Y_BITS-1 : 0] y_start,
	input bit [X_BITS-1 : 0] x_end,
	input bit [Y_BITS-1 : 0] y_end,

	output bit [X_BITS-1 : 0] out_x,
	output bit [Y_BITS-1 : 0] out_y,
	output bit done
);

	always_ff @(posedge clk) begin
		done = 'b0;

		if (rst) begin
			// reset all values back to 0
			out_x = x_start;
			out_y = y_start;
		end
		else if (enable) begin
			if (out_x == x_end) begin
				out_x = x_start;
				
				if (out_y == y_end) begin
					out_y = y_start;
					done = 'b1;
				end
				else begin
					out_y = out_y + 'b1;
				end
			end
			else begin
				out_x = out_x + 'b1;
			end
		end
	end

endmodule

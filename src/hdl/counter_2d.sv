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

	output bit [X_BITS-1 : 0] out_x,
	output bit [Y_BITS-1 : 0] out_y,
	output bit [TOTAL_BITS-1 : 0] out_total,
	output bit done
);

	always_ff @(posedge clk) begin
		done = 'b0;

		if (rst) begin
			// reset all values back to 0
			out_x = 'b0;
			out_y = 'b0;
			out_total = 'b0;
		end
		else if (enable) begin
			// advance the x and total counters
			out_x = out_x + 'b1;
			out_total = out_total + 'b1;
			
			// handle x 'overflow'
			if (out_x == WIDTH) begin
				// reset x to 0, advance the y counter
				out_x = 'b0;
				out_y = out_y + 'b1;
				
				// handle y 'overflow'
				if (out_y == HEIGHT) begin
					// reset y and total counters to 0
					out_y = 'b0;
					out_total = 'b0;
					done = 'b0;
				end
			end
		end
	end

endmodule

/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

typedef enum {
	IDLE,
	LOOP
} divider_state;

module divider #(
	parameter N_BITS = 8
) (
	input clk,
	input rst,

	input [N_BITS-1 : 0] numerator,
	input [N_BITS-1 : 0] denominator,
	input start,
	
	output bit busy,
	output bit [N_BITS-1 : 0] quotient,
	output bit [N_BITS-1 : 0] remainder,
	output bit result_valid
);

	localparam N_BITS2 = 2 * N_BITS;
	localparam N_BITS_I = $clog2(N_BITS);

	// current state
	divider_state state = IDLE;

	// values used in algorithm
	bit signed [N_BITS2-1 : 0] R; // remainder
	bit [N_BITS2-1 : 0] D; // denominator
	bit [N_BITS-1 : 0] Q; // quotient
	bit [N_BITS_I-1 : 0] i; // iteration counter

	// implement restoring division algorithm
	always @(posedge clk) begin
		if (rst) begin
			state = IDLE;
		end
		else begin
			case (state)
				IDLE: begin
					busy = 0;
					if (start) begin
						busy = 1;
						result_valid = 0;

						// intialize values
						R = numerator;
						D = denominator << N_BITS;
						Q = 0;
						i = N_BITS - 1;

						state = LOOP;
					end
				end

				LOOP: begin
					R = 2 * R - D;
					Q = Q << 1;

					if (R >= 0) begin
						Q = Q + 1;
					end
					else begin
						R = R + D;
					end

					if (i == 0) begin
						quotient = Q;
						remainder = R >> N_BITS;
						result_valid = 1;
						state = IDLE;
					end
					else begin
						i = i - 1;
					end
				end
			endcase
		end
	end

endmodule

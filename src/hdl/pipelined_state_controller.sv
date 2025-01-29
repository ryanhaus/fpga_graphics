module pipelined_state_controller #(
	parameter N_STATES = 5,
	parameter STATE_VARS_WIDTH = 8
) (
	input clk,
	input rst,

	// for inputting a new state
	input [STATE_VARS_WIDTH-1 : 0] state_vars_next,
	input state_vars_next_valid,
	output bit state_accepted, // 1 if previous state_vars was pushed in

	// inputs for indicating when a state is ready to move on
	input [N_STATES-1 : 0] state_ready,

	// output register value
	output bit [N_STATES-1 : 0][STATE_VARS_WIDTH-1 : 0] state_vars_out
);

	integer i; // used in for loop

	bit [N_STATES-1 : 0] state_occupied;

	always_ff @(posedge clk) begin
		if (rst) begin
			state_occupied = '0;
			state_accepted = '0;
			state_vars_out = '{default: '0};
		end
		else begin
			// move the last state out if it is ready
			if (state_ready[N_STATES-1] == '1) begin
				state_occupied[N_STATES-1] = '0;
				state_vars_out[N_STATES-1] = '0;
			end

			// move all other states over that are ready to be moved over
			for (i = N_STATES-2; i >= 0; i = i - 1) begin
				if (state_occupied[i + 1] == '0 && state_ready[i] == '1) begin
					state_occupied[i + 1] = '1;
					state_vars_out[i + 1] = state_vars_out[i];

					state_occupied[i] = '0;
					state_vars_out[i] = '0;
				end
			end

			// if the input state is valid, push it in, if it can be
			if (state_vars_next_valid && state_occupied[0] == '0) begin
				state_occupied[0] = '1;
				state_vars_out[0] = state_vars_next;
				state_accepted = '1;
			end
			else state_accepted = '0;
		end
	end

endmodule

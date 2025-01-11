module color_gen (
	input integer weight_a,
	input integer weight_b,
	input integer weight_c,
	output color out_col
);

	localparam R_BITS = 32 + 5;
	localparam G_BITS = 32 + 6;
	localparam B_BITS = 32 + 5;

	bit [R_BITS-1 : 0] r_result;
	bit [G_BITS-1 : 0] g_result;
	bit [B_BITS-1 : 0] b_result;

	assign out_col.r = r_result[R_BITS-1 : 32];
	assign out_col.g = g_result[G_BITS-1 : 32];
	assign out_col.b = b_result[B_BITS-1 : 32];

	always_comb begin
		r_result = 2 * 31 * weight_a;
		g_result = 2 * 63 * weight_b;
		b_result = 2 * 31 * weight_c;
	end

endmodule

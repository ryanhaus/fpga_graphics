module color_gen (
	input int_triangle in_tri,
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
		r_result = 2 * (weight_a * in_tri.a.col.r + weight_b * in_tri.b.col.r + weight_c * in_tri.c.col.r);
		g_result = 2 * (weight_a * in_tri.a.col.g + weight_b * in_tri.b.col.g + weight_c * in_tri.c.col.g);
		b_result = 2 * (weight_a * in_tri.a.col.b + weight_b * in_tri.b.col.b + weight_c * in_tri.c.col.b);
	end

endmodule

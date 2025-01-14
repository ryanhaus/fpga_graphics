module z_gen (
	input triangle in_tri,
	input integer weight_a,
	input integer weight_b,
	input integer weight_c,
	output point_val_t z_val
);

	localparam Z_VAL_BITS = 32 + 20;

	bit [Z_VAL_BITS-1 : 0] z_result;
	assign z_val = z_result[Z_VAL_BITS-1 : 32];

	always_comb begin
		z_result = 2 * (weight_a * in_tri.a.z + weight_b * in_tri.b.z + weight_c * in_tri.c.z);
	end

endmodule

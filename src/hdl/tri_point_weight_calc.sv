`include "edge_fn.sv"

module tri_point_weight_calc (
	input int_triangle in_tri,
	input int_point in_point,

	output integer tri_edge_fn,
	input integer inverse_tri_edge_fn, // must be calculated to be a fixed-point value equivalent to 1 / (tri_edge_fn)

	output integer weight_a,
	output integer weight_b,
	output integer weight_c
);

	integer abp;
	integer bcp;
	integer cap;

	always_comb begin
		tri_edge_fn = edge_fn(in_tri.a, in_tri.b, in_tri.c);
		abp = edge_fn(in_tri.a, in_tri.b, in_point);
		bcp = edge_fn(in_tri.b, in_tri.c, in_point);
		cap = edge_fn(in_tri.c, in_tri.a, in_point);
		
		weight_a = bcp * inverse_tri_edge_fn;
		weight_b = cap * inverse_tri_edge_fn;
		weight_c = abp * inverse_tri_edge_fn;
	end

endmodule

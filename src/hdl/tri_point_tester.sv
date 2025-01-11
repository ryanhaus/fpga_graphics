`include "edge_fn.sv"

module tri_point_tester (
	input point in_point,
	input triangle in_tri,
	output bit point_in_tri
);

	// see https://jtsorlinis.github.io/rendering-tutorial/
	integer signed abp;
	integer signed bcp;
	integer signed cap;
	integer signed abc;

	always_comb begin
		abp = edge_fn(in_tri.a, in_tri.b, in_point);
		bcp = edge_fn(in_tri.b, in_tri.c, in_point);
		cap = edge_fn(in_tri.c, in_tri.a, in_point);
		abc = edge_fn(in_tri.a, in_tri.b, in_tri.c);

		point_in_tri = abp >= 0 && bcp >= 0 && cap >= 0 && abc > 0;
	end

endmodule

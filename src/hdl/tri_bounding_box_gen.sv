function integer signed min;
	input integer a;
	input integer b;

	begin
		min = (a > b) ? b : a;
	end
endfunction

function integer signed max;
	input integer a;
	input integer b;

	begin
		max = (a > b) ? a : b;
	end
endfunction

module tri_bounding_box_gen #(
	parameter DISPLAY_WIDTH = 100,
	parameter DISPLAY_HEIGHT = 100
) (
	input int_triangle in_tri,
	output integer min_x,
	output integer min_y,
	output integer max_x,
	output integer max_y
);

	always_comb begin
		min_x = min(DISPLAY_WIDTH, min(in_tri.a.x, min(in_tri.b.x, in_tri.c.x)));
		min_y = min(DISPLAY_HEIGHT, min(in_tri.a.y, min(in_tri.b.y, in_tri.c.y)));
		max_x = max(0, max(in_tri.a.x, max(in_tri.b.x, in_tri.c.x)));
		max_y = max(0, max(in_tri.a.y, max(in_tri.b.y, in_tri.c.y)));
	end

endmodule

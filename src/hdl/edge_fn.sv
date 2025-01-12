`ifndef EDGE_FN_SV
`define EDGE_FN_SV

function integer signed edge_fn;
	input int_point a;
	input int_point b;
	input int_point c;

	begin
		edge_fn = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
	end
endfunction

`endif

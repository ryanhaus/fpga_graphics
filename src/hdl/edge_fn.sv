`ifndef EDGE_FN_SV
`define EDGE_FN_SV

function integer signed edge_fn;
	input point a;
	input point b;
	input point c;

	begin
		edge_fn = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
	end
endfunction

`endif

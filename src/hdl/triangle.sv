typedef struct packed {
	reg [4:0] r;
	reg [5:0] g;
	reg [4:0] b;
} color;

typedef struct packed {
	bit [7:0] int_bits;
	bit [11:0] frac_bits;
} fixed_point_8_12;

typedef fixed_point_8_12 point_val_t;

typedef struct packed {
	point_val_t x;
	point_val_t y;
	point_val_t z;
	color col;
} point;

typedef struct packed {
	point a;
	point b;
	point c;
} triangle;

typedef struct packed {
	integer signed x;
	integer signed y;
	integer signed z;
	color col;
} int_point;

typedef struct packed {
	int_point a;
	int_point b;
	int_point c;
} int_triangle;

// this is mainly to make passing triangles from the verilator testbench
// easier by padding all values to make them fit cleanly with a 32-bit
// alignment
typedef struct packed {
	point_val_t val;
	reg [(32 - $bits(point_val_t))-1 : 0] padding;
} padded_point_val_t;

typedef struct packed {
	padded_point_val_t x;
	padded_point_val_t y;
	padded_point_val_t z;
	color col;
	reg [15:0] padding;
} padded_point;

typedef struct packed {
	padded_point a;
	padded_point b;
	padded_point c;
} padded_triangle;

function triangle unpad_tri;
	input padded_triangle in_tri;

	begin
		unpad_tri.a.x = in_tri.a.x.val;
		unpad_tri.a.y = in_tri.a.y.val;
		unpad_tri.a.z = in_tri.a.z.val;
		unpad_tri.a.col = in_tri.a.col;

		unpad_tri.b.x = in_tri.b.x.val;
		unpad_tri.b.y = in_tri.b.y.val;
		unpad_tri.b.z = in_tri.b.z.val;
		unpad_tri.b.col = in_tri.b.col;

		unpad_tri.c.x = in_tri.c.x.val;
		unpad_tri.c.y = in_tri.c.y.val;
		unpad_tri.c.z = in_tri.c.z.val;
		unpad_tri.c.col = in_tri.c.col;
	end
endfunction

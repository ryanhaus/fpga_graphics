typedef struct packed {
	integer x;
	integer y;
} point;

typedef struct packed {
	reg [4:0] r;
	reg [5:0] g;
	reg [4:0] b;
} color;

typedef struct packed {
	point a;
	point b;
	point c;
	color tri_color;
} triangle;

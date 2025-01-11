typedef struct packed {
	reg [4:0] r;
	reg [5:0] g;
	reg [4:0] b;
} color;

typedef struct packed {
	integer signed x;
	integer signed y;
	integer signed z;
	color col;
} point;

typedef struct packed {
	point a;
	point b;
	point c;
} triangle;

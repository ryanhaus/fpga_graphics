#pragma once
// see src/hdl/triangle.sv

struct point {
	uint32_t y;
	uint32_t x;
};

struct triangle {
	point c;
	point b;
	point a;
};

triangle create_tri(uint32_t ax, uint32_t ay, uint32_t bx, uint32_t by, uint32_t cx, uint32_t cy) {
	triangle tri;
	tri.a.x = ax;
	tri.a.y = ay;
	tri.b.x = bx;
	tri.b.y = by;
	tri.c.x = cx;
	tri.c.y = cy;

	return tri;
}

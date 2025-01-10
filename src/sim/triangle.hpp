#pragma once
#include <math.h>
// see src/hdl/triangle.sv

#pragma pack(push, 1)

struct point {
	uint32_t y;
	uint32_t x;
};

struct color {
	uint16_t
		b: 5,
		g: 6,
		r: 5;
};

struct triangle {
	color tri_color;
	point c;
	point b;
	point a;
};

#pragma pack(pop)

color rgb(float r, float g, float b) {
	color col;
	col.r = (uint16_t)round(r * 0b11111);
	col.g = (uint16_t)round(g * 0b111111);
	col.b = (uint16_t)round(b * 0b11111);

	return col;
}

triangle create_tri(color tri_color, uint32_t ax, uint32_t ay, uint32_t bx, uint32_t by, uint32_t cx, uint32_t cy) {
	triangle tri;
	tri.tri_color = tri_color;
	tri.a.x = ax;
	tri.a.y = ay;
	tri.b.x = bx;
	tri.b.y = by;
	tri.c.x = cx;
	tri.c.y = cy;

	return tri;
}

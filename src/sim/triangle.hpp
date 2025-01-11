#pragma once
#include <math.h>
// see src/hdl/triangle.sv

#pragma pack(push, 1)

struct color {
	uint16_t
		b: 5,
		g: 6,
		r: 5;
};

struct point {
	color col;
	int32_t z;
	int32_t y;
	int32_t x;
};

struct triangle {
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

point create_point(uint32_t x, uint32_t y, uint32_t z, color col) {
	point pt;
	pt.x = x;
	pt.y = y;
	pt.z = z;
	pt.col = col;

	return pt;
}

triangle create_tri(point a, point b, point c) {
	triangle tri;
	tri.a = a;
	tri.b = b;
	tri.c = c;

	return tri;
}

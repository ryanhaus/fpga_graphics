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

struct fixed_point_8_12 {
	uint8_t _dummy; // to make struct 32 bits
	uint16_t frac_bits;
	int8_t int_bits;
};

typedef fixed_point_8_12 point_val_t;

struct point {
	uint16_t _dummy; // to make struct 64 bits
	color col;
	point_val_t z;
	point_val_t y;
	point_val_t x;
};

struct triangle {
	point c;
	point b;
	point a;
};

#pragma pack(pop)

static color rgb(float r, float g, float b) {
	color col;
	col.r = (uint16_t)round(r * 0b11111);
	col.g = (uint16_t)round(g * 0b111111);
	col.b = (uint16_t)round(b * 0b11111);

	return col;
}

static fixed_point_8_12 create_fixed_8_12(float x) {
	// splits a float into the integer and decimal parts
	float integer, decimal;
	decimal = modf(x, &integer);

	fixed_point_8_12 fixed_val;
	fixed_val.int_bits = (int8_t)integer;
	fixed_val.frac_bits = (uint16_t)(decimal * (1 << 12)) << 4;
	
	return fixed_val;
}

static point create_point(float x, float y, float z, color col) {
	point pt;
	pt.x = create_fixed_8_12(x);
	pt.y = create_fixed_8_12(y);
	pt.z = create_fixed_8_12(z);
	pt.col = col;

	return pt;
}

static triangle create_tri(point a, point b, point c) {
	triangle tri;
	tri.a = a;
	tri.b = b;
	tri.c = c;

	return tri;
}

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
	int32_t
		_padding: 12,
		frac_bits: 12,
		int_bits: 8;
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

	int32_t fixed_val_int = (int32_t)round(x * (1 << 12)) << 12;
	fixed_point_8_12 fixed_val;

	memcpy(&fixed_val, &fixed_val_int, sizeof(fixed_val));
	
	return fixed_val;
}

static float convert_fixed_8_12(fixed_point_8_12 x) {
	// converts a fixed_8_12 into a floating point number
	int32_t fixed_val_int;
	memcpy(&fixed_val_int, &x, sizeof(fixed_val_int));

	float result = (float)fixed_val_int / (float)(2 << 23);

	return result;
}

static point create_point(float x, float y, float z, color col = {0,0,0}) {
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

point translate_point(point pt, point translation) {
	float pt_float[] = {
		convert_fixed_8_12(pt.x),
		convert_fixed_8_12(pt.y),
		convert_fixed_8_12(pt.z),
	};

	float translation_float[] = {
		convert_fixed_8_12(translation.x),
		convert_fixed_8_12(translation.y),
		convert_fixed_8_12(translation.z),
	};

	float result_float[] = {
		pt_float[0] + translation_float[0],
		pt_float[1] + translation_float[1],
		pt_float[2] + translation_float[2],
	};

	return create_point(result_float[0], result_float[1], result_float[2], pt.col);
}

point rotate_point(point pt, float rotation) {
	// only rotates XZ plane about (0, 0) for now
	float x_float = convert_fixed_8_12(pt.x);
	float z_float = convert_fixed_8_12(pt.z);

	float magnitude = sqrtf(powf(x_float, 2.0) + powf(z_float, 2.0));
	float theta = atan2f(z_float, x_float);

	x_float = magnitude * cosf(theta + rotation);
	z_float = magnitude * sinf(theta + rotation);

	pt.x = create_fixed_8_12(x_float);
	pt.z = create_fixed_8_12(z_float);

	return pt;
}

triangle translate_triangle(triangle tri, point translation) {
	tri.a = translate_point(tri.a, translation);
	tri.b = translate_point(tri.b, translation);
	tri.c = translate_point(tri.c, translation);

	return tri;
}

triangle rotate_triangle(triangle tri, float rotation) {
	tri.a = rotate_point(tri.a, rotation);
	tri.b = rotate_point(tri.b, rotation);
	tri.c = rotate_point(tri.c, rotation);

	return tri;
}

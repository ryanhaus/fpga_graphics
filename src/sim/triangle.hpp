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

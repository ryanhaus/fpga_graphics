#include <SDL2/SDL.h>
#include <Vtop.h>
#include <verilated_vcd_c.h>
#include <cassert>
#include <string.h>
#include "triangle.hpp"

#define DISPLAY_WIDTH 320
#define DISPLAY_HEIGHT 240
#define WINDOW_SCALE 2

struct pixel {
	uint16_t
		r: 5,
		g: 6,
		b: 5;
};

void verilator_tick(Vtop* top, VerilatedVcdC* m_trace) {
	static uint64_t time_ps = 0;
	top->eval();
	// m_trace->dump(time_ps++);
}

void write_tri_to_vram(Vtop* top, VerilatedVcdC* m_trace, triangle tri, int vram_addr) {
	assert(sizeof(triangle) == sizeof(top->vram_wr_in));
	memcpy(&top->vram_wr_in[0], &tri, sizeof(triangle));

	top->vram_wr_addr = vram_addr;
	top->vram_wr_clk = 0;
	top->vram_wr_en = 1;
	verilator_tick(top, m_trace);
	top->vram_wr_clk = 1;
	verilator_tick(top, m_trace);
	top->vram_wr_en = 0;
	top->vram_wr_clk = 0;
}

int main() {
	// initialize SDL
	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		return 1;
	}

	// create window
	SDL_Window* window = SDL_CreateWindow(
		"Window",
		SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED,
		DISPLAY_WIDTH * WINDOW_SCALE,
		DISPLAY_HEIGHT * WINDOW_SCALE,
		SDL_WINDOW_SHOWN
	);

	if (window == NULL) {
		return 1;
	}

	// create renderer
	SDL_Renderer* renderer = SDL_CreateRenderer(
		window,
		-1,
		SDL_RENDERER_ACCELERATED
	);

	if (renderer == NULL) {
		return 1;
	}

	// create texture
	SDL_Texture* texture = SDL_CreateTexture(
		renderer,
		SDL_PIXELFORMAT_RGB565,
		SDL_TEXTUREACCESS_STREAMING,
		DISPLAY_WIDTH,
		DISPLAY_HEIGHT
	);

	if (texture == NULL) {
		return 1;
	}

	// initialize verilator
	Vtop* top = new Vtop;

	Verilated::traceEverOn(true);
	VerilatedVcdC* m_trace = new VerilatedVcdC;
	top->trace(m_trace, 99);
	m_trace->open("trace.vcd");

	// reset cycle
	top->logic_clk = 0;
	top->rst = 1;
	verilator_tick(top, m_trace);
	top->logic_clk = 1;
	verilator_tick(top, m_trace);
	top->rst = 0;
	top->logic_clk = 0;
	verilator_tick(top, m_trace);
	
	// write triangles to VRAM
	write_tri_to_vram(top, m_trace, create_tri(160, 20, 300, 220, 20, 220), 0);
	write_tri_to_vram(top, m_trace, create_tri(160, 20, 300, 20, 300, 220), 1);

	// main loop
	pixel framebuffer[DISPLAY_HEIGHT][DISPLAY_WIDTH] = { 0 };

	bool running = true;
	while (running) {
		// process events
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				running = false;
			}
		}

		// pulse logic_clk
		for (int i = 0; i < 1000 * 2; i++) {
			top->logic_clk = !top->logic_clk;
			verilator_tick(top, m_trace);
		}

		// update framebuffer
		for (int y = 0; y < DISPLAY_HEIGHT; y++) {
			for (int x = 0; x < DISPLAY_WIDTH; x++) {
				top->display_out_clk = 0;
				top->x_in = x;
				top->y_in = y;
				top->eval();
				top->display_out_clk = 1;
				top->eval();

				uint16_t pixel_out = top->pixel_out;
				pixel* px = (pixel*)&pixel_out;

				framebuffer[y][x] = *px;
			}
		}

		// display framebuffer
		SDL_UpdateTexture(texture, NULL, framebuffer, DISPLAY_WIDTH * sizeof(pixel));
		SDL_RenderClear(renderer);
		SDL_RenderCopy(renderer, texture, NULL, NULL);
		SDL_RenderPresent(renderer);
	}

	// free everything
	top->final();
	m_trace->close();
	SDL_DestroyTexture(texture);
	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();

	return 0;
}

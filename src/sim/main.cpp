#include <SDL2/SDL.h>
#include <Vtop.h>
#include <verilated_fst_c.h>
#include <cassert>
#include <string.h>
#include <math.h>
#include <stdio.h>
#include "triangle.hpp"
#include "model.hpp"

#define DISPLAY_WIDTH 320
#define DISPLAY_HEIGHT 240
#define WINDOW_SCALE 2

struct pixel {
	uint16_t
		r: 5,
		g: 6,
		b: 5;
};

void verilator_tick(Vtop* top, VerilatedFstC* m_trace) {
	static uint64_t time_ps = 0;
	top->eval();
	// m_trace->dump(time_ps++);
}

void write_tri_to_vram(Vtop* top, VerilatedFstC* m_trace, triangle tri, int vram_addr) {
	assert(sizeof(triangle) <= sizeof(top->vram_wr_in_padded));
	memcpy(&top->vram_wr_in_padded[0], &tri, sizeof(triangle));

	top->vram_wr_addr = vram_addr;
	top->vram_wr_clk = 0;
	top->vram_wr_en = 1;
	verilator_tick(top, m_trace);
	top->vram_wr_clk = 1;
	verilator_tick(top, m_trace);
	top->vram_wr_en = 0;
	top->vram_wr_clk = 0;
}

void update_vram(Vtop* top, VerilatedFstC* m_trace) {
	static float t = 0.0f;
	
	for (int i = 0; i < N_TRIANGLES; i++) {
		triangle tri = TRIANGLES[i];
		tri = rotate_triangle(tri, t);
		tri = translate_triangle(tri, create_point(0.0, 0.0, 2.5));

		write_tri_to_vram(top, m_trace, tri, i);
	}

	t += 0.1;
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
	VerilatedFstC* m_trace = new VerilatedFstC;
	top->trace(m_trace, 99);
	m_trace->open("trace.fst");

	// reset cycle
	top->logic_clk = 1;
	top->rst = 1;
	verilator_tick(top, m_trace);
	for (int i = 0; i < 2; i++) {
		top->logic_clk = !top->logic_clk;
		verilator_tick(top, m_trace);
	}
	top->rst = 0;
	top->logic_clk = 0;
	verilator_tick(top, m_trace);

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

		// write triangles to VRAM
		update_vram(top, m_trace);

		// start the frame
		top->frame_start = 1;
		top->logic_clk = 1;
		verilator_tick(top, m_trace);
		top->logic_clk = 0;
		verilator_tick(top, m_trace);
		top->frame_start = 0;

		// pulse logic_clk until the frame generation has started
		const uint64_t MAX_TICKS = 1000000; // maximum number of clock cycles per frame
		uint64_t tick_count = 0;
		while (top->frame_done && tick_count < MAX_TICKS) {
			top->logic_clk = 0;
			verilator_tick(top, m_trace);

			top->logic_clk = 1;
			verilator_tick(top, m_trace);

			tick_count++;
		}

		// pulse logic_clk until the frame is done
		while (!top->frame_done && tick_count < MAX_TICKS) {
			top->logic_clk = 0;
			verilator_tick(top, m_trace);

			top->logic_clk = 1;
			verilator_tick(top, m_trace);

			tick_count++;
		}

		printf("Frame completed in %lu clock cycles\n", tick_count);

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

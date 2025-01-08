#include <SDL2/SDL.h>
#include <Vtop.h>

#define WINDOW_WIDTH 320
#define WINDOW_HEIGHT 240
#define WINDOW_SCALE 2

struct pixel {
	uint16_t
		r: 5,
		g: 6,
		b: 5;
};

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
		WINDOW_WIDTH * WINDOW_SCALE,
		WINDOW_HEIGHT * WINDOW_SCALE,
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
		WINDOW_WIDTH,
		WINDOW_HEIGHT
	);

	if (texture == NULL) {
		return 1;
	}

	// initialize verilator
	Vtop* top = new Vtop;

	// main loop
	pixel framebuffer[WINDOW_HEIGHT][WINDOW_WIDTH] = { 0 };

	bool running = true;
	while (running) {
		// process events
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				running = false;
			}
		}

		// update framebuffer
		for (int y = 0; y < WINDOW_HEIGHT; y++) {
			for (int x = 0; x < WINDOW_WIDTH; x++) {
				top->clk = 0;
				top->x_in = x;
				top->y_in = y;
				top->eval();
				top->clk = 1;
				top->eval();

				uint16_t pixel_out = top->pixel_out;
				pixel* px = (pixel*)&pixel_out;

				framebuffer[y][x] = *px;
			}
		}

		// display framebuffer
		SDL_UpdateTexture(texture, NULL, framebuffer, WINDOW_WIDTH * sizeof(pixel));
		SDL_RenderClear(renderer);
		SDL_RenderCopy(renderer, texture, NULL, NULL);
		SDL_RenderPresent(renderer);
	}

	// free everything
	top->final();
	SDL_DestroyTexture(texture);
	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();

	return 0;
}

#include <SDL2/SDL.h>
#include <Vtop.h>

#define DISPLAY_WIDTH 320
#define DISPLAY_HEIGHT 240
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

	// write some data to the framebuffer on the FPGA
	for (int y = 0; y < DISPLAY_HEIGHT; y++) {
		for (int x = 0; x < DISPLAY_WIDTH; x++) {
			top->wr_clk = 0;
			pixel color = { 0, y, x };
			uint16_t* px = (uint16_t*)&color;
			top->wr_in = *px;
			top->x_in = x;
			top->y_in = y;
			top->eval();
			top->wr_clk = 1;
			top->eval();
		}
	}

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

		// update framebuffer
		for (int y = 0; y < DISPLAY_HEIGHT; y++) {
			for (int x = 0; x < DISPLAY_WIDTH; x++) {
				top->rd_clk = 0;
				top->x_in = x;
				top->y_in = y;
				top->eval();
				top->rd_clk = 1;
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
	SDL_DestroyTexture(texture);
	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();

	return 0;
}

#include <SDL2/SDL.h>

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

	// main loop
	pixel framebuffer[WINDOW_HEIGHT][WINDOW_WIDTH] = { 0 };

	bool running = true;
	while (running) {
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				running = false;
			}
		}

		SDL_UpdateTexture(texture, NULL, framebuffer, WINDOW_WIDTH * sizeof(pixel));
		SDL_RenderClear(renderer);
		SDL_RenderCopy(renderer, texture, NULL, NULL);
		SDL_RenderPresent(renderer);
	}

	return 0;
}

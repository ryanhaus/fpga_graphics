bin/main: src/*
	mkdir -p bin
	g++ src/main.cpp \
		-o bin/main \
		$(shell sdl2-config --libs --cflags)

clean:
	rm -rf bin

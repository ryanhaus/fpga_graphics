bin/sim: src/*
	mkdir -p bin
	verilator src/hdl/top.sv \
		-y src/hdl \
		--Mdir bin \
		--cc \
		--exe \
		--build src/sim/main.cpp \
		-CFLAGS $(shell sdl2-config --cflags) \
		-LDFLAGS $(shell sdl2-config --libs) \
		-sv \
		-o sim \
		src/sim/*.cpp

clean:
	rm -rf bin

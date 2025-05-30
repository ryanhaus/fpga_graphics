bin/sim: src/* res/*
	mkdir -p bin
	./src/sim/stl_convert.py
	verilator src/hdl/top.sv \
		-y src/hdl \
		--Mdir bin \
		--cc \
		--exe \
		--build src/sim/main.cpp \
		-CFLAGS "-O3 $(shell sdl2-config --cflags)" \
		-LDFLAGS $(shell sdl2-config --libs) \
		-sv \
		-o sim \
		--trace-fst \
		--trace-structs \
		--trace-max-array 500 \
		--trace-max-width 200 \
		src/sim/*.cpp

lint:
	verilator src/hdl/top.sv \
		-y src/hdl \
		--lint-only

clean:
	rm -rf bin
	rm trace.*

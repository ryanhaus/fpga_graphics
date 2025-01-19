#!/bin/python3
# converts a STL file to a C++ header file
import numpy
from random import random as rand
from stl import mesh

mesh = mesh.Mesh.from_file("res/gordon_freeman.stl")
triangles = zip(mesh.v0, mesh.v1, mesh.v2)

header_file = ""

header_file += "#pragma once\n"
header_file += "// AUTOMATICALLY GENERATED: see src/sim/stl_convert.py\n"
header_file += "#include \"triangle.hpp\"\n"
header_file += "static triangle TRIANGLES[] = {\n";

for tri in triangles:
    header_file += "\tcreate_tri("

    r = rand()
    g = rand()
    b = rand()

    header_file += f"create_point({tri[0][0]}, {tri[0][1]}, {tri[0][2]}, rgb({r}, {g}, {b})), "
    header_file += f"create_point({tri[1][0]}, {tri[1][1]}, {tri[1][2]}, rgb({r}, {g}, {b})), "
    header_file += f"create_point({tri[2][0]}, {tri[2][1]}, {tri[2][2]}, rgb({r}, {g}, {b}))"

    header_file += "),\n";

header_file += "};\n"

header_file += "\n"
header_file += f"const size_t N_TRIANGLES = {int(mesh.v0.size / 3)};\n"

f = open("src/sim/model.hpp", "w")
f.write(header_file)
f.close()

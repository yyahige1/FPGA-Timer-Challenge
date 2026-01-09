from vunit import VUnit

vu = VUnit.from_argv()

lib = vu.add_library("lib")
lib.add_source_files("src/*.vhd")
lib.add_source_files("tb/*.vhd")

vu.main()


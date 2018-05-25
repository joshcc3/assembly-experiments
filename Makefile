MAP_REDUCE_SFILES := $(shell find src -type f -name '*.s')

MAP_REDUCE_OBJFILES := $(MAP_REDUCE_SFILES:src/%.s=target/%.o)

all: target/map_reduce/map_reduce

target/%.o: src/%.s
	mkdir -p $(dir $@)
	nasm -f elf64 -g -F dwarf -i src/ $^ -o $@

target/map_reduce/map_reduce: $(MAP_REDUCE_OBJFILES) target/map_reduce/start.o
	mkdir -p target/map_reduce
	ld -o $@ $^

clean:
	rm -rf target

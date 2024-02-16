mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

build:
	cargo lambda build --release --arm64 --output-format binary

clean:
	rm -r target

all: kernel builddir
	cp -rv utils/* build/
	mkdir -p build/boot/
	mv ksrc/kernel.lua build/boot/
	echo "Copy the files in 'build' to your hard disk."

kernel:
	$(MAKE) -C ksrc

builddir:
	echo "Cleaning build directory"
	rm -rf build
	mkdir build

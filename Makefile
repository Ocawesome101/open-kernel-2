all: kernel builddir
	cp -rv utils/* build/
	mkdir -p build/boot/
	mv ksrc/kernel.lua build/boot/
	echo "Copy the files in 'build' to your hard disk."

kernel:
	if [ ! -f "ksrc/kernel.lua" ]; then echo "You must compile the kernel first!"; exit 1; fi

builddir:
	echo "Cleaning build directory"
	rm -rf build
	mkdir build

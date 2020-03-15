# Compile Open Kernel 2

PROC = luacomp

kernel: preproc lua version
	$(PROC) kbase.lua -O kernel.lua

lua:
	if ! [ -x "/usr/bin/lua" ]; then \
		error "Cannot continue"; \
		exit 1; \
	fi

preproc:
	if ! [ -x "`which $(PROC)`" ]; then \
		error "$(PROC) not found"; \
		exit 1; \
	fi

clean:
	rm -f kernel.lua
	rm -f modules/version.lua

version:
	lua5.3 build_id.lua > modules/version.lua

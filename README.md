# open-kernel-2
Open Kernel 2. With a build system.

This is the new Open Kernel 2 repository (the old, unsupported one is [here.](https://github.com/ocawesome101/open-kernel-2-old)).

## building
Building Open Kernel 2 requires that `make` and [`luacomp`](https://github.com/Adorable-Catgirl/luacomp) or [`luaproc`](https://raw.githubusercontent.com/ocawesome101/random-oc-stuff/master/Utils/luaproc.lua) be available. You will also need `git` and `lua5.2`.

To build Open Kernel 2, run the following commands (assuming you are running Linux):
```sh
git clone https://github.com/ocawesome101/open-kernel-2 # clone the repo
cd open-kernel-2/ksrc # go to the kernel source directory
make # compile it
cd .. # back to the repository root
make # finish compiling it!
```

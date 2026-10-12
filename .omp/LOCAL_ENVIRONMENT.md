# Development Environment

## Machine

- Machine name: `fedora-work`
- Hostname: `fedora-work`
- Architecture: `x86_64`
- Kernel: `Linux 7.2.8-200.fc44.x86_64`
- Operating system: `Fedora Linux 44 (KDE Plasma Desktop Edition)`
- Shell: `/bin/bash`
- Repository root: `/home/aurja/Programming/GEF_Cpp`

## OMP

- OMP
  - Command: `omp`
  - Path: `/home/aurja/.local/bin/omp`
  - Version: `omp/18.8.4`
- Project OMP directory: `.omp/`
- Project LSP configuration: `.omp/lsp.json`
- Project session directory: `.omp/sessions/`
- Local environment file: `.omp/LOCAL_ENVIRONMENT.md`

## Python

- Python
  - Command: `python3`
  - Path: `/home/aurja/.pyenv/shims/python3`
  - Version: `Python 3.14.7`

- basedpyright
  - Command: `basedpyright`
  - Path: `/home/aurja/.local/bin/basedpyright`
  - Version: `basedpyright 1.39.10`

- Ruff
  - Command: `ruff`
  - Path: `/home/aurja/.local/bin/ruff`
  - Version: `ruff 0.16.6`

- pytest
  - Command: `pytest`
  - Path: `/home/aurja/.local/bin/pytest`
  - Version: `pytest 9.1.1`

## C and C++

- GCC
  - Command: `gcc`
  - Path: `/usr/bin/gcc`
  - Version: `gcc (GCC) 16.2.1 20260819 (Red Hat 16.2.1-2)`

- G++
  - Command: `g++`
  - Path: `/usr/bin/g++`
  - Version: `g++ (GCC) 16.2.1 20260819 (Red Hat 16.2.1-2)`

- Clang
  - Command: `clang`
  - Path: `/usr/bin/clang`
  - Version: `clang version 22.1.8 (Fedora 22.1.8-4.fc44)`

- Clang++
  - Command: `clang++`
  - Path: `/usr/bin/clang++`
  - Version: `clang version 22.1.8 (Fedora 22.1.8-4.fc44)`

- clangd
  - Command: `clangd`
  - Path: `/usr/bin/clangd`
  - Version: `clangd version 22.1.8 (Fedora 22.1.8-4.fc44)`

- clang-tidy
  - Command: `clang-tidy`
  - Path: `/usr/bin/clang-tidy`
  - Version: `LLVM version 22.1.8`

- clang-format
  - Command: `clang-format`
  - Path: `/usr/bin/clang-format`
  - Version: `clang-format version 22.1.8 (Fedora 22.1.8-4.fc44)`

- CMake
  - Command: `cmake`
  - Path: `/usr/bin/cmake`
  - Version: `cmake version 4.3.0`

- CTest
  - Command: `ctest`
  - Path: `/usr/bin/ctest`
  - Version: `ctest version 4.3.0`

- Ninja
  - Command: `ninja`
  - Path: `/usr/bin/ninja`
  - Version: `1.13.2`

- Universal Ctags
  - Command: `ctags`
  - Path: `/usr/bin/ctags`
  - Version: `Universal Ctags 6.2.1, Copyright (C) 2015-2025 Universal Ctags Team`

- GDB
  - Command: `gdb`
  - Path: `/usr/bin/gdb`
  - Version: `GNU gdb (Fedora Linux) 17.2-4.fc44`

- GNU patch
  - Command: `patch`
  - Path: `/usr/bin/patch`
  - Version: `GNU patch 2.8`

- glibc
  - Version: `ldd (GNU libc) 2.43`

### Compiler/runtime validation

Each facility below was verified when this file was generated: a small program was
compiled with the flags and run, with no diagnostic. The TSan probe runs two threads.

- Compiler warnings:
  - `-Wall -Wextra -Wpedantic -Werror`
  - Verified with: `g++` `clang++`
- AddressSanitizer:
  - `-fsanitize=address -fno-omit-frame-pointer`
  - Verified with: `g++` `clang++`
- UndefinedBehaviorSanitizer:
  - `-fsanitize=undefined -fno-omit-frame-pointer`
  - Verified with: `g++` `clang++`
- ThreadSanitizer:
  - `-fsanitize=thread -fno-omit-frame-pointer`
  - Verified with: `g++` `clang++`
- Debug-friendly sanitizer option:
  - `-fno-omit-frame-pointer`
- TSan cannot be combined with ASan in one build; the project uses separate
  presets (`asan-ubsan`, `tsan`).

## FreeBASIC

- fbc (FreeBASIC compiler; not on PATH)
  - Path: `/home/aurja/Downloads/FreeBASIC-1.10.1-linux-x86_64/bin/fbc`
  - Version: `FreeBASIC Compiler - Version 1.10.1 (2023-12-24), built for linux-x86_64 (64bit)`
  - Distribution tarball: `/home/aurja/Downloads/FreeBASIC-1.10.1-linux-x86_64.tar.gz`,
    SHA-256 `844aa9e997f9ff93566a28f05c502cf24f5aefefc64c4aca0e7a304994f508bc`
  - Project tools find it through `GEF_FBC`, falling back to
    `/home/aurja/Downloads/FreeBASIC-1.10.1-linux-x86_64/bin/fbc`.
  - Every invocation prints harmless `libtinfo.so.5: no version information available`
    and ``Symbol `ospeed' has different size`` loader warnings on stderr.

## SQL

- sqls
  - Command: `sqls`
  - Path: `/home/aurja/go/bin/sqls`
  - Version: `sqls version Version:0.2.48, Revision:HEAD`

## Go

- Go
  - Command: `go`
  - Path: `/usr/bin/go`
  - Version: `go version go1.26.8-X:nodwarf5 linux/amd64`

## Git

- Git
  - Command: `git`
  - Path: `/usr/bin/git`
  - Version: `git version 2.55.0`

## Executable search path

```text
/home/aurja/go/bin
/home/aurja/.pyenv/plugins/pyenv-virtualenv/shims
/home/aurja/.pyenv/shims
/home/aurja/.pyenv/bin
/home/aurja/go/bin
/home/aurja/.pyenv/plugins/pyenv-virtualenv/shims
/home/aurja/.pyenv/bin
/home/aurja/go/bin
/home/aurja/.pyenv/plugins/pyenv-virtualenv/shims
/home/aurja/.pyenv/bin
/home/aurja/.local/bin
/home/aurja/bin
/usr/share/Modules/bin
/usr/local/bin
/usr/bin
/usr/local/sbin
/usr/sbin
/home/aurja/.local/bin/
/home/aurja/.lmstudio/bin
/home/aurja/.lmstudio/bin
/home/aurja/.local/bin/
/home/aurja/.lmstudio/bin
/home/aurja/.local/bin/
/home/aurja/.lmstudio/bin
```

## Notes

- Prefer commands available through `PATH` rather than hard-coded absolute paths.

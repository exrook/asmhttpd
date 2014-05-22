cmake_minimum_required(VERSION 2.8)

set(SOURCES src/main.asm)

# Default cmake ASM linking is dumb, fix it
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "<CMAKE_LINKER> <FLAGS> <CMAKE_ASM_NASM_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET>")
set(CMAKE_ASM_NASM_LINK_FLAGS "-m elf_i386")
enable_language(ASM_NASM)
project(httpd ASM_NASM)

set(CMAKE_ASM_LINK_EXECUTABLE ld)

add_custom_target(cclean git clean -Xdf)

add_executable(httpd ${SOURCES})

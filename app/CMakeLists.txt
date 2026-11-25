cmake_minimum_required(VERSION 3.6)

project(MaterialFiles C)

add_library(hiddenapi SHARED
        src/main/jni/hiddenapi.c)
target_compile_options(hiddenapi
        PRIVATE
        -Wall
        -Werror)

# syscall's logging is compiled out, so it doesn't link to Android's log.
add_library(syscall SHARED
        src/main/jni/syscall.c)
target_compile_options(syscall
        PRIVATE
        -Wall
        -Werror)

# Android's log functions, doing nothing, for the libraries that come built
# (see silenceNativeLogs in build.gradle).
add_library(nlg SHARED
        src/main/jni/nlg.c)
target_compile_options(nlg
        PRIVATE
        -Wall
        -Werror)

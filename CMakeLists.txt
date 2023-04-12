cmake_minimum_required(VERSION 3.17.0)
project(hamming VERSION 1.0 LANGUAGES C CXX CUDA)

#==========================================
#   hammingCPU
#==========================================

file(GLOB_RECURSE hammingCPU_SRC "hamming/main.cpp")

add_executable(hammingCPU ${hammingCPU_SRC})

set_property(TARGET hammingCPU PROPERTY CXX_STANDARD 17)

#==========================================
#   hammingGPU
#==========================================

file(GLOB_RECURSE hammingGPU_SRC "hamming/hamming.cu")

add_executable(hammingGPU ${hammingGPU_SRC})

set_property(TARGET hammingGPU PROPERTY CXX_STANDARD 17)
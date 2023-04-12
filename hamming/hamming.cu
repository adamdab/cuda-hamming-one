#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"


#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>
#include <fstream>
#include <chrono>


#define FILENAME "vector_sequences_file.txt"
#define DEV "DEV_vector_sequences_file.txt"

#define MAX_WORD_SIZE 12000 // in int32_t size

__global__ void hamming_one(int32_t* d_data, int N, int P);
__device__ uint32_t count_set_bits(int32_t n);
__device__ int get_shm_starting_index(int id, int ints_per_word);

void generate_bit_sequences(const int N, const int L);
void read_bit_sequences(std::string path, int32_t*& h_input, int& N, int& L, int& ints_per_word);
int32_t set_bit(int32_t n, int k, int b);
void set_thread_and_block_counts(int N, int ints_per_word, int& block_count, int& thread_count);
void initialize_CUDA_memory(int N, int P);
void clean();

void print_time_difference(std::chrono::steady_clock::time_point start, std::chrono::steady_clock::time_point end);


const int BITS_IN_INT = (8 * sizeof(int32_t));
int32_t* h_data, * d_data;


int main()
{

    int N, L, ints_per_word;

    generate_bit_sequences(100000, 1000);

    read_bit_sequences(DEV, h_data, N, L, ints_per_word);
    
    initialize_CUDA_memory(N, ints_per_word);

    int block_count, thread_count;
    set_thread_and_block_counts(N, ints_per_word, block_count, thread_count);

    std::chrono::steady_clock::time_point start = std::chrono::high_resolution_clock::now();
    std::cout << "Comparing... \n";
    hamming_one <<<block_count, thread_count >>> (d_data, N, ints_per_word);
    cudaDeviceSynchronize();
    std::chrono::steady_clock::time_point end = std::chrono::high_resolution_clock::now();
    std::cout << "End of comparing... ";
    print_time_difference(start, end);

    clean();
    std::cout << "End of Program\n";
    return 0;
}


__global__ void hamming_one(int32_t* d_data, int N, int ints_per_word)
{
    __shared__ int32_t shm[MAX_WORD_SIZE];
    int key_word_id = blockIdx.x * blockDim.x + threadIdx.x;
    int hamming_distance;
    int shm_id = get_shm_starting_index(threadIdx.x, ints_per_word);

    for (int i = 0; i < ints_per_word; i++)
    {
        // put thread's key word into shared memory
        shm[shm_id + i * 32] = d_data[key_word_id * ints_per_word + i];
    }

    // compare each word that is after key word
    for (int compare_word_id = key_word_id + 1; compare_word_id < N; compare_word_id++)
    {
        hamming_distance = 0;

        // compare each part of word
        for (int i = 0; i < ints_per_word; i++)
        {
            int32_t xor =shm[shm_id + i * 32] ^ d_data[compare_word_id * ints_per_word + i];
            hamming_distance += count_set_bits(xor);
            if (hamming_distance > 1) break; // if hamming distance is greater than 1 stop checking
        }

        if (hamming_distance == 1) printf("Pair [%d] and [%d]\n", key_word_id, compare_word_id);

    }

}

__device__ uint32_t count_set_bits(int32_t n)
{
    if (n == 0) return 0; // all zeros
    if ((n & (n - 1)) == 0) return 1; // is power of 2
    return 2; // more  than one 1
}

__device__ int get_shm_starting_index(int id, int ints_per_word)
{
    int id_32 = id / 32;
    int id_bank = id % 32;
    return id_32 * (32 * ints_per_word) + id_bank; // offset + id
}

void generate_bit_sequences(const int N, const int L)
{
    std::cout << "Begin generation ...\n";
    std::chrono::steady_clock::time_point start = std::chrono::high_resolution_clock::now();
    srand((unsigned)time(NULL));
    std::ofstream out(FILENAME);
    out << N << std::endl << L << std::endl;
    int number;
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < L; j++)
        {
            number = rand() % 2;
            number == 0 ? out << "0" : out << "1";
        }
        out << std::endl;
    }
    std::chrono::steady_clock::time_point end = std::chrono::high_resolution_clock::now();
    std::cout << "End generation ... ";
    print_time_difference(start, end);
    out.close();
}

void  read_bit_sequences(std::string path, int32_t*& h_input, int& N, int& L, int& ints_per_word)
{
    std::ifstream stream;
    std::chrono::steady_clock::time_point start = std::chrono::high_resolution_clock::now();
    try
    {
        std::cout << "Started reading file\n";
        stream.open(path, std::ios::in);
        stream >> N >> L;

        ints_per_word = ceil((double)L / BITS_IN_INT);
        
        h_input = new int32_t[N * ints_per_word];
        int curr_int = 0;
        int curr_bit = BITS_IN_INT - 1;

        for (int i = 0; i < N * ints_per_word; ++i)
            h_input[i] = 0;

        for (int i = 0; i < N; ++i)
        {
            for (int j = 0; j < L; ++j)
            {
                char ch;
                stream >> ch;
                h_input[curr_int] = set_bit(h_input[curr_int], curr_bit, ch == '1' ? 1 : 0);
                curr_bit--;
                if (curr_bit == -1)
                {
                    curr_bit = BITS_IN_INT - 1;
                    curr_int++;
                }
            }
            curr_int++;
            curr_bit = BITS_IN_INT - 1;
        }

        stream.close();
        std::chrono::steady_clock::time_point end = std::chrono::high_resolution_clock::now();
        std::cout << "Successfully read file ";
        print_time_difference(start, end);
    }
    catch (...)
    {
        std::chrono::steady_clock::time_point end = std::chrono::high_resolution_clock::now();
        std::cout << "Error handling input file ";
        print_time_difference(start, end);
        return;
    }
}

int32_t set_bit(int32_t n, int k, int b)
{
    // set k-th bit of n to bit b
    int32_t mask = 1 << k;
    return ((n & ~mask) | (b << k));
}

void set_thread_and_block_counts(int N, int ints_per_word, int& block_count, int& thread_count)
{
    thread_count = MAX_WORD_SIZE / ints_per_word - 32;
    block_count = ceil((double)N / thread_count);
}

void initialize_CUDA_memory(int N, int ints_per_word)
{
    // allocate memory
    cudaMalloc(&d_data, N * ints_per_word * sizeof(int32_t));
    // copy data from host  to device
    cudaMemcpy(d_data, h_data, N * ints_per_word * sizeof(int32_t), cudaMemcpyHostToDevice);
    std::cout << "CUDA memory initialized\n";
}

void clean()
{
    std::cout << "Clean\n";
    cudaFree(d_data);
    delete[] h_data;
}


void print_time_difference(std::chrono::steady_clock::time_point start, std::chrono::steady_clock::time_point end)
{
    double time_taken = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    time_taken *= 1e-9;
    printf("[It took %.9f sec]\n", time_taken);
    
}
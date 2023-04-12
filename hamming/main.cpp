#include <iostream>
#include <fstream>
#include <chrono>


#define FILENAME "vector_sequences_file.txt"
#define DEV "DEV_vector_sequences_file.txt"


void generate_bit_sequences(const int N, const int L);
void read_bit_sequences(std::string fileName, int& N, int& L, int& ints_per_word);
int set_bit(int n, int kth, int b);
void clean();
void check_two_words(int first, int second, int ints_per_word);
unsigned int count_set_bits(int n);

void print_time_difference(std::chrono::steady_clock::time_point start, std::chrono::steady_clock::time_point end);

int* h_input;
const int BITS_IN_INT = (8 * sizeof(int));

int main() 
{
	int ints_per_word, N, L;

	generate_bit_sequences(100000,1000);

	read_bit_sequences(FILENAME,N,L, ints_per_word);

	std::chrono::steady_clock::time_point start = std::chrono::high_resolution_clock::now();
	std::cout << "Comparing...\n ";
	for (int i = 0; i < N; i++)
	{
		for (int j = i + 1; j < N; j++) check_two_words(i, j, ints_per_word);
	}
	std::chrono::steady_clock::time_point end = std::chrono::high_resolution_clock::now();
	std::cout << "End of comparing... ";
	print_time_difference(start, end);
	
	clean();

	std::cout << "End Of Program" << std::endl;
	
	return 0;
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
			number == 0 ? out<<"0" : out<<"1";
		}
		out<< std::endl;
	}
	std::chrono::steady_clock::time_point end = std::chrono::high_resolution_clock::now();
	std::cout << "End generation ... ";
	print_time_difference(start, end);
	out.close();
}

int set_bit(int n, int kth, int b)
{
	int mask = 1 << kth;
	return ((n & ~mask) | (b << kth));
}

void read_bit_sequences(std::string fileName, int& N, int& L ,int& ints_per_word)
{
	std::ifstream stream;
	std::chrono::steady_clock::time_point start = std::chrono::high_resolution_clock::now();
	try
	{
		std::cout << "Started reading file" << std::endl;
		stream.open(fileName, std::ios::in);
		stream >> N >> L;
		ints_per_word = ceil((double)L / BITS_IN_INT);

		h_input = new int[N * ints_per_word];
		
		
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
		std::cout << "Error handling input file" << std::endl;
		print_time_difference(start, end);
		return;
	}
}

void clean()
{
	std::cout << "---CLEAN---\n";
	delete[] h_input;
	
}

void check_two_words(int first, int second, int ints_per_word)
{
	int hamming_distance = 0;
	for (int i = 0; i < ints_per_word; ++i)
	{
		int xor = h_input[first* ints_per_word + i] ^ h_input[second* ints_per_word + i];

		if (xor != 0)
		{
			hamming_distance += count_set_bits(xor);
			if (hamming_distance >= 2) return;
			
		}
	}
	if (hamming_distance == 1)
	{
		printf("Pair [%d] and [%d]\n", first , second);
	}
}

unsigned int count_set_bits(int n)
{
	if (n == 0) return 0; // all zeros
	if ((n & (n - 1)) == 0) return 1; // is power of 2
	return 2; // more  than one 1
}

void print_time_difference(std::chrono::steady_clock::time_point start, std::chrono::steady_clock::time_point end)
{
	double time_taken = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
	time_taken *= 1e-9;
	printf("[It took %.9f sec]\n", time_taken);
}
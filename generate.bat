git submodule update --init --recursive

mkdir _build
cd _build
call cmake ..
copy ..\hamming\DEV_vector_sequences_file.txt .\

PAUSE
using Distributed
using Distributions
using Dates
using CUDAnative, CuArrays, CUDAdrv, BenchmarkTools

function kernel(V_neu, V_alt, alpha, j)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
end

function main()
    alpha = 0.5
    n = 1024
    x = 10
    V = CuArray{Float64,2}(zeros(n, x))
    for j in 1:(x-1)
        @cuda (1, n) kernel(V[:, j + 1], V[:,j], alpha, j)
    end
end

# help?> blockIdx
# search: blockIdx blockDim

#   blockIdx()::CuDim3

#   Returns the block index within the grid.

# help?> threadIdx
# search: threadIdx

#   threadIdx()::CuDim3

#   Returns the thread index within the block. 

# help?> blockDim
# search: blockDim blockIdx isblockdev

#   blockDim()::CuDim3

#   Returns the dimensions of the block.
using Distributed
using Distributions
using Dates
using CUDAnative, CuArrays, CUDAdrv, BenchmarkTools

function kernel(V, alpha, j)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    V[i, j + 1] = V[i, j]*alpha + j
    if i == 1
        @cuprintln(blockIdx().x, blockIdx().y, blockIdx().z)
        @cuprintln(threadIdx().x, threadIdx().y, threadIdx().z)
        @cuprintln(i)
    end
    return
end

function main()
    alpha = 0.5
    n = 1024
    x = 10
    V = CuArray{Float64,2}(ones(n, x))
    for j in 1:(x-1)
        @cuda threads=n kernel(V, alpha, j) 
        # println("hier" * "$j")
    end
    # j = 1
    # @cuda threads=n kernel(V, alpha, j) 
    println(V)
end

main()

@device_code_warntype main()

n = 1024
xs, ys, zs = CuArray(rand(n)), CuArray(rand(n)), CuArray(zeros(n))

function kernel_vadd(out, a, b)
  i = (blockIdx().x-1) * blockDim().x + threadIdx().x
  out[i] = a[i] + b[i]
  return
end

@cuda threads=n kernel_vadd(zs, xs, ys)
println(zs)

function dummy()
    return
end

@cuda blocks=50 threads=(30, 15)  dummy()

# const int block_size = 30;
# dim3 dimBlock(block_size, ne); // 30, 15
# dim3 dimGrid(nx/block_size, 1); // 50, 1 | 30*50 = 1500 = nx

# const int ix  = blockIdx.x * blockDim.x + threadIdx.x;
# const int ie  = threadIdx.y;

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
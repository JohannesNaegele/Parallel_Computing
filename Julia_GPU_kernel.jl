using Distributed
using Distributions
using Dates
using CUDAnative, CuArrays, CUDAdrv, BenchmarkTools

function kernel(V_neu, V_alt, alpha, j)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    V_neu[i] = V_alt[i]*alpha + j
    return
end

function main()
    alpha = 0.5
    n = 1024
    x = 10
    V = CuArray{Float64,2}(zeros(n, x))
    for j in 1:(x-1)
        @cuda threads=n kernel(V[:, j + 1], V[:,j], alpha, j)
    end
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
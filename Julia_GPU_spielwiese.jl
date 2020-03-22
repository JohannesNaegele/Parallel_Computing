using CUDAnative, CuArrays, BenchmarkTools, CUDAdrv

CUDAdrv.name(CuDevice(0))

function addieren(x, y, res, scalar)
    for i in 1:length(x)
        res[i] = x[i] + y[i] * scalar
    end
    # res[] = x .+ y
    return nothing
end

function doppelt(x, y, scalar)
    for i in 1:length(x)
        scalar[1] *= 1.1
        for j in 1:1000
            scalar[1] = 1/j * x[i] * y[i]
        end
    end
    return nothing
end

function main1()
    c = CuArrays.zeros(10000)
    a = CuArrays.rand(10000)
    b = CuArrays.rand(10000)
    d = 5

    @cuda addieren(a, b, c, d)
    println(typeof(a))
end

function main2()
    a = CuArrays.rand(10000)
    b = CuArrays.rand(10000)
    d = CuArrays.zeros(1)
    println(typeof(d))

    @cuda doppelt(a, b, d)
    println(d)
end

main1()

main2()

a = cu([1,2,3])
a = [1,2,3]
a = CuArray{Float64,1}([1,2,3])
# same
a = CuVector{Float64}([1,2,3])

nothing
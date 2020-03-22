using CUDAnative, CuArrays, BenchmarkTools

function addieren(x, y, res)
    for i in 1:length(x)
        res[i] = x[i] + y[i]
    end
    # res[] = x .+ y
    return nothing
end

function main()
    c = CuArrays.zeros(10000)
    a = CuArrays.rand(10000)
    b = CuArrays.rand(10000)

    @cuda addieren(a, b, c)
    println(typeof(a))
end

main()

a = CuArrays.rand(10000)
b = rand(10000)
a .+ b

fill!(y_d, 2)
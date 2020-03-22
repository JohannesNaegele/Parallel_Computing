using CUDAnative, CuArrays, BenchmarkTools

struct daten
    scalar::Float64
    resultat::CuArray{Float64,3}
end

function main()
    println("ok")
    value = daten(2., CuArray{Float64,3}(zeros(10, 10, 10)))
    a = CuArray{Float64,2}(ones(10, 10))
    value.resultat[:,:,10] = a
    println("passt")
    for i in 9:-1:1
        @sync for j in 1:10
            value.resultat[:,j,i] = j*value.resultat[:,j,i+1]
        end
    end
    println("passt")
    for j in 10:-1:1
        println(value.resultat[:,:,j])
    end
end

main()

a = daten(2., CuArray{Float64,3}(zeros(10, 10, 10)))
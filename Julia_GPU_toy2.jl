# function Value(age, ix, ie)
#     VV = -10^3;
#     for(ixp = 1:nx)
#         expected = 0.0;
#         if(age < T)
#             for(iep = 1:ne)
#                 expected = expected + P[ie, iep]*V[age+1, ixp, iep];
#             end
#         end
#         cons = (1 + r)*xgrid[ix] + egrid[ie]*w - xgrid[ixp];
#         utility = (cons^(1-ssigma))/(1-ssigma) + bbeta*expected;
#         if(cons <= 0)
#             utility = -10^5;
#         end
#         if(utility >= VV)
#             VV = utility;
#         end
#     end
#     return(VV);
# end

# function faster()
#     for(age = T:-1:1)
#         for(ix = 1:nx)
#             for(ie = 1:ne)
#                 V[age, ix, ie] = Value(age, ix, ie);
#             end
#         end
#     end
# end

# function val(a,b,c)

# end

using Distributed
using Distributions
using Dates
using CUDAnative, CuArrays, CUDAdrv, BenchmarkTools

struct params
    ne::Int64
    nx::Int64
    T::Int64
    ssigma::Float64
    bbeta::Float64
    w::Float64
    r::Float64
    # P::CuArray{Float64,2}
    # xgrid::CuVector{Float64}
    # egrid::CuVector{Float64}
    # V::CuArray{Float64,2}
end

# a = params(1,1,1,1,1,1.,1.,1.,1.)
# isbits(a)

# Function that computes value function, given vector of state variables
function value_all(params::params, age::Int64, xgrid::CuVector{Float64}, egrid::CuVector{Float64}, P::CuArray{Float64,2}, V::CuArray{Float64,2}, ix::Int64, ie::Int64)
    ne      = params.ne
    nx      = params.nx
    T       = params.T
    ssigma  = params.ssigma
    bbeta   = params.bbeta
    w       = params.w
    r       = params.r

    VV      = -10.0^3;
    ixpopt  = 0;


    for ixp = 1:nx
        expected = 0.0;
        if(age < T)
            for iep = 1:ne
                expected = expected + P[ie, iep]*V[ixp, iep];
            end
        end

        cons  = (1 + r)*xgrid[ix] + egrid[ie]*w - xgrid[ixp];

        utility = (cons^(1-ssigma))/(1-ssigma) + bbeta*expected;

        if(cons <= 0)
            utility = -10.0^(5);
        end

        if(utility >= VV)
            VV = utility;
            ixpopt = ixp;
        end

        utility = 0.0;
    end

    return(VV);

end

function main()

    # Grid for x
    nx = 1500;
    xmin = 0.1;
    xmax = 4.0;

    # Grid for e: parameters for Tauchen
    ne = 15;
    ssigma_eps = 0.02058;
    llambda_eps = 0.99;
    m = 1.5;

    # Utility function
    ssigma = 2;
    bbeta = 0.97;
    T = 10;

    # Prices
    r = 0.07;
    w = 5;

    # Initialize the grid for X
    xgrid = CuArray{Float64,1}(zeros(nx))

    # Initialize the grid for E and the transition probability matrix
    egrid = CuArray{Float64,1}(zeros(ne))
    P = CuArray{Float64,2}(zeros(ne, ne))

    # Initialize value function V
    V = CuArray{Float64,3}(zeros(T, nx, ne))
    V_tomorrow = CuArray{Float64,2}(zeros(nx, ne))

    # Initialize value function as a shared array
    tempV = CuArray{Float64,1}(zeros(ne*nx))

    println("vor grid")

    #--------------------------------#
    #         Grid creation          #
    #--------------------------------#

    # Grid for capital (x)
    size = nx;
    xstep = (xmax - xmin) /(size - 1);
    for i = 1:nx
    xgrid[i] = xmin + (i-1)*xstep;
    end

    # Grid for productivity (e) with Tauchen (1986)
    size = ne;
    ssigma_y = sqrt((ssigma_eps^2) / (1 - (llambda_eps^2)));
    estep = 2*ssigma_y*m / (size-1);
    for i = 1:ne
    egrid[i] = (-m*sqrt((ssigma_eps^2) / (1 - (llambda_eps^2))) + (i-1)*estep);
    end

    # Transition probability matrix (P) Tauchen (1986)
    mm = egrid[2] - egrid[1];
    for j = 1:ne
    for k = 1:ne
        if(k == 1)
        P[j, k] = cdf(Normal(), (egrid[k] - llambda_eps*egrid[j] + (mm/2))/ssigma_eps);
        elseif(k == ne)
        P[j, k] = 1 - cdf(Normal(), (egrid[k] - llambda_eps*egrid[j] - (mm/2))/ssigma_eps);
        else
        P[j, k] = cdf(Normal(), (egrid[k] - llambda_eps*egrid[j] + (mm/2))/ssigma_eps) - cdf(Normal(), (egrid[k] - llambda_eps*egrid[j] - (mm/2))/ssigma_eps);
        end
    end
    end

    # Exponential of the grid e
    for i = 1:ne
    egrid[i] = exp(egrid[i]);
    end

    println("nach grid")

    #--------------------------------#
    #     Life-cycle computation     #
    #--------------------------------#

    print(" \n")
    print("Life cycle computation: \n")
    print(" \n")

    start = Dates.unix2datetime(time())
    ########################
    currentState = params(ne,nx,T,ssigma,bbeta,w,r)
    age = 1
    ie = 1
    V_tomorrow = V[age,:,:]

    println(isbits(currentState))
    function value(ix)
        return value_all(currentState, age, xgrid, egrid, P, V_tomorrow, ix, ie)
    end
    println(length(V[1,:,1]))
    indizes = CuArray{Int64,1}([i for i in 1:length(V[1,:,1])])
    # indizes = [i for i in 1:length(V[1,:,1])]
    for age = T:-1:1
        # @sync for ix = 1:nx
        V_tomorrow = V[age,:,:]
        @sync for ie = 1:ne
            V[age, :, ie] = value.(indizes)
            # V[age, ix, ie] = value(ix)
        end
        # end
        finish = convert(Int, Dates.value(Dates.unix2datetime(time())- start))/1000;
        print("Age: ", age, ". Time: ", finish, " seconds. \n")
    end
    print("\n")
    finish = convert(Int, Dates.value(Dates.unix2datetime(time())- start))/1000;
    print("TOTAL ELAPSED TIME: ", finish, " seconds. \n")

    #---------------------#
    #     Some checks     #
    #---------------------#

    print(" \n")
    print(" - - - - - - - - - - - - - - - - - - - - - \n")
    print(" \n")
    print("The first entries of the value function: \n")
    print(" \n")

    # I print the first entries of the value function, to check
    for i = 1:3
        print(round(V[1, 1, i], digits=5), "\n")
    end
end

main()

function main2()
    dim = 1000
    function kernel(P, a)
        sum = 0
        for i in 1:length(P)
            sum += P[i]/i*a
        end
        return sum
    end
    println("test")
    V = CuArray{Float64,1}(zeros(dim))
    P = CuArray{Float64,1}(rand(dim))
    call_kernel(i) = kernel(P, i)
    # @sync for i in 1:length(V)
    #     V[i] = call_kernel(i)
    # end
    # println([i for i in 1:length(V)])
    indizes = CuArray{Int64,1}([i for i in 1:length(V)])
    # indizes = [i for i in length(V)]
    @sync V[:] = call_kernel.(indizes)
    # println(V)
end

main2()
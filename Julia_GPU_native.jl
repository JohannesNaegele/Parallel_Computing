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
function value_all(params::params, age::Int64, xgrid::CuVector{Float64}, egrid::CuVector{Float64}, P::CuArray{Float64,2}, V::CuArray{Float64,3})
    
    ix = (blockIdx().x-1) * blockDim().x + threadIdx().x
    ie = threadIdx().y
    
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
                expected = expected + P[ie, iep]*V[age + 1, ixp, iep];
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

    V[age, ix, ie] = VV

    return nothing

end
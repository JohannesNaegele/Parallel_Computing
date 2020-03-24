#--------------------------------#
#         House-keeping          #
#--------------------------------#

using Distributed
using Distributions
using Dates
using CUDAnative, CuArrays, CUDAdrv, BenchmarkTools

#--------------------------------#
#         Initialization         #
#--------------------------------#

# Number of cores/workers
addprocs(6)
CuArrays.allowscalar(true)

struct params
    ind::Int64
    ne::Int64
    nx::Int64
    T::Int64
    age::Int64
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
function value(state, params::params, age::Int64, xgrid::CuVector{Float64}, egrid::CuVector{Float64}, P::CuArray{Float64,2}, V::CuArray{Float64,2})

    ind     = params.ind
    age     = params.age
    ne      = params.ne
    nx      = params.nx
    T       = params.T
    P       = params.P
    xgrid   = params.xgrid
    egrid   = params.egrid
    ssigma  = params.ssigma
    bbeta   = params.bbeta
    w       = params.w
    r       = params.r
    V       = params.V

    ix      = convert(Int, floor((ind-0.05)/ne))+1;
    ie      = convert(Int, floor(mod(ind-0.05, ne))+1);

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

function faster()

    ne = 15
    nx = 1500

    block_size = 30
    threads = (block_size, ne)
    blocks = (nx/block_size, 1)
    for T:-1:1
        gpu_call(value, (params, age, xgrid, egrid, P, V))
end


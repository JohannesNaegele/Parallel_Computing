using CUDAnative, CuArrays, BenchmarkTools, CUDAdrv, Distributions

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

###########################

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

struct modelState
    ind::Int64
    ne::Int64
    nx::Int64
    T::Int64
    age::Int64
    P::CuArray{Float64,2}
    xgrid::CuVector{Float64}
    egrid::CuVector{Float64}
    ssigma::Float64
    bbeta::Float64
    V::CuArray{Float64,2}
    w::Float64
    r::Float64
end

age = 1
ind = 1

currentState = modelState(ind,ne,nx,T,age,P,xgrid,egrid,ssigma,bbeta, V_tomorrow,w,r)

isbits(currentState)

function value(ind, )age

    ind     = currentState.ind
    age     = currentState.age
    ne      = currentState.ne
    nx      = currentState.nx
    T       = currentState.T
    P       = currentState.P
    xgrid   = currentState.xgrid
    egrid   = currentState.egrid
    ssigma  = currentState.ssigma
    bbeta   = currentState.bbeta
    w       = currentState.w
    r       = currentState.r
    V       = currentState.V

    ix      = convert(Int, floor((ind-0.05)/ne))+1;
    ie      = convert(Int, floor(mod(ind-0.05, ne))+1);

    VV      = -10.0^3;
    ixpopt  = 0;


    # for ixp = 1:nx

    #     expected = 0.0;
    #     if(age < T)
    #         for iep = 1:ne
    #         expected = expected + P[ie, iep]*V[ixp, iep];
    #         end
    #     end

    #     cons  = (1 + r)*xgrid[ix] + egrid[ie]*w - xgrid[ixp];

    #     utility = (cons^(1-ssigma))/(1-ssigma) + bbeta*expected;

    #     if(cons <= 0)
    #         utility = -10.0^(5);
    #     end

    #     if(utility >= VV)
    #         VV = utility;
    #         ixpopt = ixp;
    #     end

    #     utility = 0.0;
    # end

    # return(VV);
    return nothing
end

@cuda value(currentState)


a = [1 2 3; 4 5 6]

function trick(a)
    a[1] = 2
end

b = a[:,1]

trick(b)

println(a)
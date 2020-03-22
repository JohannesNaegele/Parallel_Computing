function Value(age, ix, ie)
    VV = -10^3;
    for(ixp = 1:nx)
        expected = 0.0;
        if(age < T)
            for(iep = 1:ne)
                expected = expected + P[ie, iep]*V[age+1, ixp, iep];
            end
        end
        cons = (1 + r)*xgrid[ix] + egrid[ie]*w - xgrid[ixp];
        utility = (cons^(1-ssigma))/(1-ssigma) + bbeta*expected;
        if(cons <= 0)
            utility = -10^5;
        end
        if(utility >= VV)
            VV = utility;
        end
    end
    return(VV);
end

function faster()
    for(age = T:-1:1)
        for(ix = 1:nx)
            for(ie = 1:ne)
                V[age, ix, ie] = Value(age, ix, ie);
            end
        end
    end
end

function val(a,b,c)

end

struct params
    ind::Int64
    ne::Int64
    nx::Int64
    T::Int64
    age::Int64
    P::Array{Float64,2}
    xgrid::Vector{Float64}
    egrid::Vector{Float64}
    ssigma::Float64
    bbeta::Float64
    # V::Array{Float64,2}
    w::Float64
    r::Float64
end

function value_all(currentState::params, age, P, ix, ie, V, V_exp)

    # ind     = currentState.ind
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

    # ix      = convert(Int, floor((ind-0.05)/ne))+1;
    # ie      = convert(Int, floor(mod(ind-0.05, ne))+1);

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

# currentState, age, P, V_exp, ie gegeben
# V ~ V[age, :, ie]
function value(V, ix)
    return value_all(currentState, age, P, ix, ie, V, V_exp)
end
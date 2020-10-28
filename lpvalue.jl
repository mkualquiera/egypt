using AutoHashEquals

@auto_hash_equals struct LPValue
    m::Number
    n::Number
end

LPValue(n) = LPValue(0,n)
Base.one(::Type{LPValue}) = LPValue(1)
Base.zero(::Type{LPValue}) = LPValue(0)
Base.zero(::LPValue) = LPValue(0)
Base.convert(::Type{Number},x::LPValue) = x.m*100000+x.n
Base.transpose(x::String) = x

function Base.isless(x::LPValue,y::LPValue)
    if x.m != y.m 
        return x.m < y.m
    else
        return x.n < y.n
    end
    return true
end

function Base.isless(x::LPValue,y::Number)
    return isless(x,LPValue(y))
end

function Base.min(x::LPValue,y::LPValue)
    if x < y return x end
    if y < x return y end
    if x == y return x end
end

function Base.abs(x::LPValue)
    return LPValue(abs(x.m),abs(x.n))
end

function Base.inv(x::LPValue)
    @assert x.m == 0
    return LPValue(0,inv(x.n))
end

function Base.adjoint(x::LPValue)
    @assert x.m == 0
    return LPValue(0,inv(x.n))
end

function Base.:(*)(x::LPValue,y::LPValue)
    @assert y.m == 0
    return LPValue(x.m*y.n,x.n*y.n)
end

function Base.:(*)(x::LPValue,y::Number)
    return LPValue(x.m*y,x.n*y)
end

function Base.:(/)(x::LPValue,y::LPValue)
    @assert x.m == 0
    return LPValue(x.m/y.n,x.n/y.n)
end

function Base.:(+)(x::LPValue,y::LPValue)
    return LPValue(x.m+y.m,x.n+y.n)
end

function Base.:(+)(x::LPValue,y::Number)
    return LPValue(x.m,x.n+y)
end

function Base.:(+)(x::Number,y::LPValue)
    return LPValue(y.m,y.n+x)
end

function Base.:(-)(x::LPValue,y::LPValue)
    return LPValue(x.m-y.m,x.n-y.n)
end

function Base.:(-)(x::LPValue,y::Number)
    return LPValue(x.m,x.n-y)
end

function Base.:(-)(x::Number,y::LPValue)
    return LPValue(-y.m,y.n-x)
end

function Base.show(io::IO, x::LPValue)
    hasm = false
    if x.m != 0
        print(io,string(x.m))
        print(io,"M")
        hasm = true
    end
    if x.n != 0
        if x.n > 0 && hasm
            print(io,"+")
        end
        print(io,string(x.n))
    end
    if x.n == 0 && x.m == 0
        print(io,"0")
    end
end
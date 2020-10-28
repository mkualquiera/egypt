include("lpvalue.jl")

function solutionofbase(X,C,A,b,VB)
    CB = hcat(map(x->C[findfirst(y->y==x,X)],VB)...)
    B = hcat(map(x->A[:,findfirst(y->y==x,X)[2]],VB)...)
    Binv = inv(B)
    Ap = Binv * A
    bp = Binv * transpose(b)
    Cp = CB * Binv * A - C
    Z = CB * Binv * transpose(b)
    return Cp, Z, Ap, bp
end

function findnewbase(X, VB, Cp, Ap, bp)
    possibleenterings = findall(x->x==min(Cp...)&&x<0,Cp)
    if length(possibleenterings) == 0 return :solved end
    enteringid = possibleenterings[rand(1:length(possibleenterings))][2]
    reasons = ((x,y)->if y == 0 -1 else x/y end).(bp, Ap[:,enteringid])
    acceptablereasons = filter(x->x>0,reasons)
    if length(acceptablereasons) == 0 return :unfeasible end
    possibleexitings = findall(x->x==min(acceptablereasons...),reasons)
    exitingid = possibleexitings[rand(1:length(possibleexitings))][1]
    return VB[exitingid] => X[enteringid]
end

function solvesimplex(X,C,A,b,VB,logger)
    Cp, Z, Ap, bp = solutionofbase(X,C,A,b,VB)
    status = :starting
    logger(X,C,A,b,VB,Cp,Z,Ap,bp,status)
    while true
        status = findnewbase(X,VB,Cp,Ap,bp)
        if status == :unfeasible || status == :solved break end
        VB = replace(VB,status)
        Cp, Z, Ap, bp = solutionofbase(X,C,A,b,VB)
        logger(X,C,A,b,VB,Cp,Z,Ap,bp,status)
    end
    logger(X,C,A,b,VB,Cp,Z,Ap,bp,status)
    return VB,Cp,Z,Ap,bp,status
end

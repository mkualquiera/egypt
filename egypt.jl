include("lpvalue.jl")

function solutionofbase(X,C,A,b,VB)
    CB = hcat(map(x->C[findfirst(y->y==x,X)],VB)...)
    B = hcat(map(x->A[:,findfirst(y->y==x,X)[2]],VB)...)
    Binv = inv(B)
    Ap = Binv * A
    bp = Binv * b
    Cp = CB * Binv * A - C
    Z = CB * Binv * b
    return Cp, Z, Ap, bp
end

function findnewbase(X, VB, Cp, Ap, bp)
    possibleenterings = findall(x->x==min(Cp...)&&x<0,Cp)
    if length(possibleenterings) == 0 return :solved end
    #enteringid = possibleenterings[rand(1:length(possibleenterings))][2]
    enteringid = possibleenterings[1][2]
    reasons = ((x,y)->y <= 0 ? -1 : x/y).(bp, Ap[:,enteringid])
    acceptablereasons = filter(x->x>0,reasons)
    if length(acceptablereasons) == 0 return :unbounded end
    possibleexitings = findall(x->x==min(acceptablereasons...),reasons)
    #exitingid = possibleexitings[rand(1:length(possibleexitings))][1]
    exitingid = possibleexitings[1][1]
    return VB[exitingid] => X[enteringid]
end

function solvesimplex(X,C,A,b,VB,logger)
    Cp, Z, Ap, bp = solutionofbase(X,C,A,b,VB)
    status = :starting
    logger(X,C,A,b,VB,Cp,Z,Ap,bp,status)
    while true
        status = findnewbase(X,VB,Cp,Ap,bp)
        if status == :unbounded || status == :solved break end
        VB = replace(VB,status)
        Cp, Z, Ap, bp = solutionofbase(X,C,A,b,VB)
        logger(X,C,A,b,VB,Cp,Z,Ap,bp,status)
    end
    logger(X,C,A,b,VB,Cp,Z,Ap,bp,status)
    return VB,Cp,Z,Ap,bp,status
end

function standardizerestriction(X,C,A,R,i)
    nX = copy(X)
    nC = copy(C)
    nA = copy(A)
    nR = copy(R)
    if R[i,1] == "<=" 
        nX = hcat(X, [ "S"*string(i) ])
        nC = hcat(C, [ 0 ])
        nA = hcat(A, [ k == i ? 1 : 0 for k=1:size(A)[1], l=[1] ])
        nR[i,1] = "="
    elseif R[i,1] == "="
        nX = hcat(X, [ "A"*string(i) ])
        nC = hcat(C, [ LPValue(1,0) ])
        nA = hcat(A, [ k == i ? 1 : 0 for k=1:size(A)[1], l=[1] ])
    elseif R[i,1] == ">="
        nX = hcat(X, [ "E"*string(i) "A"*string(i) ])
        nC = hcat(C, [ 0 LPValue(-1,0) ])
        nA = hcat(A, [ k == i ? -1 : 0 for k=1:size(A)[1], l=[1] ],
                     [ k == i ? 1 : 0 for k=1:size(A)[1], l=[1] ])
    end
    return nX, nC, nA, nR
end

function solveproblem(D,C,A,R,b,CR,twophases)
    X = [ "X"*string(i) for j=[ 1 ], i=1:size(C)[2] ]
    if D == "min"
        C *= -1
    end
    for i in 1:size(A)[1]
        X, C, A, R = standardizerestriction(X, C, A, R, i)
    end
    VB = hcat([X[:,i] for j=[1], 
        i=(findall(x->sum(x)==1,collect(eachcol(A))))]...)

    function logger(x,c,a,b,vb,cp,z,ap,bp,status)
        println(status)
        names = hcat([ "Z" ], x, "ld")
        funcobj = hcat([ 1 ], cp, z)
        li = transpose(vb)
        lower = hcat(li, ap, bp)
        final = vcat(names, funcobj, lower)
        final = map(x->x isa Number && x < 10^-10 && x > -10^-10 ? 0 : x, final)
        display(final)
    end
    if twophases
        firstphasec = map(x->x[1]=='A' ? -1 : 0,X)
        firstsolution = solvesimplex(X, firstphasec, A, b, VB, logger)[1]
        artificialindices = map(y->y[2],findall(x->x[1]=='A',X))
        newindices = transpose(filter(x->!(x in artificialindices), 
            collect(1:size(A)[2])))
        X = hcat([X[i] for j = [ 1 ], i=newindices]...)
        A = hcat([A[:,i] for j = [ 1 ], i=newindices]...)
        C = hcat([C[i] for j = [ 1 ], i=newindices]...)
        solvesimplex(X, C, A, b, firstsolution, logger)
    else
        solvesimplex(X, C, A, b, VB, logger)
    end
end
using Mimi

include("fund.jl")
using .Fund

m = Fund.getfund()
run(m)

explore(m)

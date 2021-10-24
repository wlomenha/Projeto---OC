
using DelimitedFiles,JuMP,  Gurobi

#path = "D:\\mndzvd\\Documentos\\GitHub\\learning-julia\\agrupamento\\toy.txt"

path = "D:\\GitHub - Projects\\Projeto - OC\\ufl_50.txt"

# include("relaxacao.jl")

num_cli, num_fac, c, f = leitura_arquivo(path)

C = 1:num_cli
F = 1:num_fac
K = 25

m = Model(Gurobi.Optimizer)

@variable(m, x[i in F, j in C] >= 0)
@variable(m, y[i in F], Bin)

@objective(m, Min, sum(c[i,j]*x[i,j] for i in F, j in C) + sum(y[i]*f[i] for i in F))

@constraint(m, atr[j in C], sum(x[i,j] for i in F) == 1)
@constraint(m, turn[i in F, j in C], x[i,j] <= y[i])
@constraint(m, median, sum(y[i] for i in F) == K)

optimize!(m)
opt = objective_value(m)
x_opt = value.(x)
y_opt = value.(y)
using JuMP, Gurobi, LightGraphs, DelimitedFiles, GraphPlot

path = "D:\\GitHub - Projects\\Projeto - OC\\pb_500rnd0700.txt"

function plotGraph(graph)
    nodelabel = 1:nv(graph)
    p = gplot(graph, nodelabel = nodelabel)
    display(p)
end

function leitura_arquivo(path)
    m = readdlm(path)[1,1] # Numero de produtos
    n = readdlm(path)[1,2] # Numero de lances 

    # Conjuntos
    P = 1:m # Conjunto de produtos
    L = 1:n # Conjunto de lances

    a = zeros(Int,m,n)
    c = zeros(n)

    for j in L
        c[j] = readdlm(path)[2,j]
    end

    for i in P
        nLances = readdlm(path)[2*i+1,1]

        if nLances > 0
            for lance in 1:nLances 
                j = readdlm(path)[2*i+2,lance]
                a[i,j] = 1
            end
        end
    end

    return m, n, c, a 
end 

function print_solution(model, m, n)
    P = 1:m # Conjunto de produtos
    L = 1:n # Conjunto de lances

    for i in P
        for j in L
            if value(x[j]) == 1 && a[i,j] == 1
                println("O produto ", i, " foi coberto pelo lance ", j)
            end 
        end 
    end 

    println("O lucro total obtido foi: ", objective_value(model))
end 

function create_graph(a, m, n)
    G = LightGraphs.SimpleGraph(n)

    P = 1:m # Conjunto de produtos
    L = 1:n # Conjunto de lances

    for i in P 
        for j in L 
            for j2 in L
                if j != j2 && a[i,j] == 1 && a[i,j2] == 1 
                    add_edge!(G, j, j2)
                end 
            end 
        end 
    end 
    return G
end 

function relaxacao_linear(model)
    JuMP.relax_integrality(model)
    optimize!(model)
    return objective_value(model)
end 

function find_cliques(G, clique, candidatos, excluidos, output)
    if candidatos == [] && excluidos == []
        push!(output, clique)
        return
    end

    for v ∈ candidatos[:]
        R2 = clique ∪ [v]
        P2 = candidatos ∩ LightGraphs.neighbors(G, v)
        X2 = excluidos ∩ LightGraphs.neighbors(G, v)
        find_cliques(G, R2, P2, X2, output)
        
        filter!(e->e!=v, candidatos)
        
        excluidos = excluidos ∪ [v]
    end
end

m, n, c, a = leitura_arquivo(path)
L = 1:n # Conjunto de lances
P = 1:m # Conjunto de produtos
G = create_graph(a,m,n)
plotGraph(G)

clique = Int32[]
excluidos = Int64[]
candidatos = Array(L)
out = Array{Int32}[]

find_cliques(G, clique, candidatos, excluidos, out)

function my_callback_function(cb_data)
    x_vals = callback_value.(Ref(cb_data), x)
    # println("Relaxação linear", x_vals)

    for cliq ∈ out
        soma = 0
        for j ∈ cliq
            soma += x_vals[j]
        end
        if soma > 1 
            con = @build_constraint(
                sum(x[j] for j in cliq) <= 1
            )
            # println("Adicionando $(con)")
            MOI.submit(model, MOI.UserCut(cb_data), con)
        end
    end
end

function optimal()
    model = Model(Gurobi.Optimizer)

    MOI.set(model, MOI.RawParameter("PreCrush"), 1) # Habilitar cortes do tipo UserCuts
    MOI.set(model, MOI.RawParameter("Cuts"), 0) # Desabilitar cortes
    MOI.set(model, MOI.RawParameter("Presolve"), 0) # Desabilitar presolve
    MOI.set(model, MOI.RawParameter("Heuristics"), 0) # Desabilitar heurísticas
    MOI.set(model, MOI.RawParameter("OutputFlag"), 0) # Desabilitar log  

    @variable(model, x[j in L] >= 0, Bin)
    @constraint(model, disponibilidade[i in P], sum(a[i,j]*x[j] for j in L) <= 1)
    @objective(model, Max, sum(c[j]*x[j] for j in L))

    MOI.set(model, MOI.UserCutCallback(), my_callback_function) # Desabilitar quando quiser ver sem cortes

    optimize!(model)
    #print_solution(model, m, n)
    num_nodes = MOI.get(model, MOI.NodeCount())
    # relaxacao_linear(model)
    return num_nodes
end 

model = Model(Gurobi.Optimizer)

MOI.set(model, MOI.RawParameter("PreCrush"), 1) # Habilitar cortes do tipo UserCuts
MOI.set(model, MOI.RawParameter("Cuts"), 0) # Desabilitar cortes
MOI.set(model, MOI.RawParameter("Presolve"), 0) # Desabilitar presolve
MOI.set(model, MOI.RawParameter("Heuristics"), 0) # Desabilitar heurísticas
MOI.set(model, MOI.RawParameter("OutputFlag"), 0) # Desabilitar log  

@variable(model, x[j in L] >= 0, Bin)
@constraint(model, disponibilidade[i in P], sum(a[i,j]*x[j] for j in L) <= 1)
@objective(model, Max, sum(c[j]*x[j] for j in L))

MOI.set(model, MOI.UserCutCallback(), my_callback_function) # Desabilitar quando quiser ver sem cortes

optimize!(model)
print_solution(model, m, n)
num_nodes = MOI.get(model, MOI.NodeCount())
# relaxacao_linear(model)

println(num_nodes)
tempo = @elapsed optimal()


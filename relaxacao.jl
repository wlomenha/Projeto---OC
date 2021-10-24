
using DelimitedFiles

#path = "D:\\GitHub - Projects\\Projeto - OC\\toy.txt"

path = "D:\\GitHub - Projects\\Projeto - OC\\pmed20.txt"

function leitura_arquivo(path)
    num_fac = readdlm(path)[1,1]
    num_cli = readdlm(path)[1,2]

    c = zeros(num_fac, num_cli)
    f = readdlm(path)[2,:]

    for j in 1:num_cli
        for i in 1:num_fac
            c[i,j] = readdlm(path)[i+2, j]
        end
    end

    return num_cli, num_fac, c, f
end

function leitura_arquivo2(path)
    num_fac = readdlm(path)[1,1]
    num_cli = readdlm(path)[1,2]
    K = readdlm(path)[1,3]
    c = zeros(num_fac, num_cli)
    f = zeros(num_fac)
    for k in 1:num_cli
        i = readdlm(path)[k+1,1]
        j = readdlm(path)[k+1,2]
        c[i,j] = readdlm(path)[k+1,3]
    end
    f[1:num_fac] .= floor(maximum(c)/2)
    return num_cli, num_fac, c, f, K
end










function subproblema(c, u, f, K, num_fac, num_cli)
    x = zeros(num_fac, num_cli)
    y = zeros(num_fac) #abrir ou não a facilidade
    v = zeros(num_fac) #custo lagrangiano (ajuda no subproblema)

    for i in 1:num_fac
        v[i] = f[i]
        for j in 1:num_cli
            v[i] = v[i] + min(0, c[i,j] - u[j])
        end 
    end

    idx = sortperm(v) #lista dos índices
    for i in idx[1:K]
        y[i] = 1
    end 

    for i in 1:num_fac
        for j in 1:num_cli
            if y[i] == 1 && c[i,j] - u[j] < 0
                x[i,j] = 1
            end
        end 
    end

    lb = 0.0 #lower bound
    for j in 1:num_cli
        lb = lb + u[j]
        for i in 1:num_fac
            if x[i,j] == 1
                lb = lb + c[i,j] - u[j]
            end 
        end
    end
    
    for i in 1:num_fac
        if y[i] == 1 
            lb = lb + f[i]
        end 
    end 

    return x, y, lb
end

function upper_bound(y, num_fac, num_cli, c, f)
    x = zeros(num_fac, num_cli)
    
    # Se a facilidade abriu, atribuir clientes mais próximos a ele (de menor custo)
    for j in 1:num_cli
        idx = argmin(c[:,j] + (1 .- y) .* maximum(c))
        x[idx, j] = 1
    end

    ub = 0.0
    for i in 1:num_fac
        for j in 1:num_cli
            if x[i,j] == 1
                ub = ub + c[i,j]*x[i,j]
            end 
        end
    end

    for i in 1:num_fac
        if y[i] == 1 
            ub = ub + f[i]
        end 
    end 

    return ub, x
end


maxIter = 10000
p_i = 2
pi_min = 0.0001
#subgradiente
function subgradiente(maxIter, p_i, pi_min)

    num_cli, num_fac, c, f , K= leitura_arquivo2(path)

    best_lim_inf = -Inf
    best_lim_sup = Inf

    x_best = zeros(num_fac, num_cli)
    y_best = zeros(num_fac, num_cli)

    u = zeros(num_cli)
    improve = 0
    #K = 4

    for k in 1:maxIter    
        x_sub, y_sub, z = subproblema(c, u, f, K, num_fac, num_cli)

        if z > best_lim_inf
            best_lim_inf = z
            improve = 0
        else
            improve += 1
        end

        ub, x_up = upper_bound(y_sub, num_fac, num_cli, c, f)

        if ub < best_lim_sup
            best_lim_sup = ub 
            x_best = x_up
            y_best = y_sub
        end 

        if best_lim_sup - best_lim_inf < 1
            println("Parando por otimalidade (z_up == z_low) - iteração ", k)
            break
        end

        if improve >= maxIter/20
            p_i = p_i/2
            improve = 0
            if p_i < pi_min
                println("Parando por pi pequeno (iteração ", k, ")")
                break
            end
        end

        s = zeros(num_cli)
        norm = 0
        for j in 1:num_cli
            s[j] = 1
            for i in 1:num_fac
                s[j] -= x_sub[i,j]
            end
            norm += s[j]
        end 

        mi = p_i*((ub-z)/(norm)^2)

        for j in 1:num_cli
            u[j] = u[j] + mi*s[j]
        end 

        if mi < pi_min
            break
        end
    end
end

num_cli, num_fac, c, f , K= leitura_arquivo2(path)

best_lim_inf = -Inf
best_lim_sup = Inf

x_best = zeros(num_fac, num_cli)
y_best = zeros(num_fac, num_cli)

u = zeros(num_cli)
improve = 0
#K = 4

for k in 1:maxIter    
    x_sub, y_sub, z = subproblema(c, u, f, K, num_fac, num_cli)

    if z > best_lim_inf
        best_lim_inf = z
        improve = 0
    else
        improve += 1
    end

    ub, x_up = upper_bound(y_sub, num_fac, num_cli, c, f)

    if ub < best_lim_sup
        best_lim_sup = ub 
        x_best = x_up
        y_best = y_sub
    end 

    if best_lim_sup - best_lim_inf < 1
        println("Parando por otimalidade (z_up == z_low) - iteração ", k)
        break
    end

    if improve >= maxIter/20
        p_i = p_i/2
        improve = 0
        if p_i < pi_min
            println("Parando por pi pequeno (iteração ", k, ")")
            break
        end
    end

    s = zeros(num_cli)
    norm = 0
    for j in 1:num_cli
        s[j] = 1
        for i in 1:num_fac
            s[j] -= x_sub[i,j]
        end
        norm += s[j]
    end 

    mi = p_i*((ub-z)/(norm)^2)

    for j in 1:num_cli
        u[j] = u[j] + mi*s[j]
    end 

    if mi < pi_min
        break
    end
end


subgradiente(maxIter, p_i, pi_min)

println(best_lim_inf)
println(best_lim_sup)

tempo = @elapsed subgradiente(maxIter, p_i, pi_min)




using Pkg
#Pkg.add("DataFrames")

using DataFrames
using JuMP
using HiGHS
using Plots
using Statistics
using Random
using StatsKit
using CairoMakie, GeoMakie


#Modelo de teste para um modelo de Set Coverage usando distâncias e dados gerados pelo chat GPT!!!
# Random.seed!(1234); #Setando semente

# #Lista de bairros de belo horizonte
# #lista de bairros, com 0 sendo latitude e longitude e 1 a estimativa da população!!
# bairros_bh = Dict(
#     "Afonso Pena" => ((-19.9345, -43.9343), 10000),  # Exemplo: 10.000 pessoas
#     "Alto Barroca" => ((-19.9378, -43.9311), 8000),
#     "Alto Santa Lúcia" => ((-19.9342, -43.9830), 5000),
#     "Barroca" => ((-19.9339, -43.9385), 7000),
#     "Bela Vista" => ((-19.9335, -43.9350), 12000),
#     "Buritis" => ((-19.9725, -43.9613), 15000),
#     "Centro" => ((-19.9301, -43.9378), 20000),
#     "Cidade Nova" => ((-19.9199, -43.9325), 11000),
#     "Dom Silvério" => ((-19.9097, -43.9581), 3000),
#     "Funcionários" => ((-19.9350, -43.9362), 9000),
#     "Gameleira" => ((-19.9704, -43.9749), 4000),
#     "Horto" => ((-19.9359, -43.9488), 2500),
#     "Lourdes" => ((-19.9352, -43.9354), 7000),
#     "Savassi" => ((-19.9380, -43.9331), 15000),
#     "São Pedro" => ((-19.9313, -43.9412), 5000),
#     "Sion" => ((-19.9523, -43.9386), 6000),
#     "Santa Efigênia" => ((-19.9367, -43.9323), 8000),
#     "Estoril" => ((-19.9743, -43.9636), 4000),
#     "Belvedere" => ((-19.9604, -43.9565), 10000),
#     "Nova Suíça" => ((-19.9330, -43.9330), 9000),
#     "Palmeiras" => ((-19.9433, -43.9490), 11000),
#     "Vila da Serra" => ((-19.9581, -43.9523), 3000),
#     "São Lucas" => ((-19.9518, -43.9479), 2000),
#     "Coração Eucarístico" => ((-19.8856, -43.9431), 1500),
#     "Caiçara" => ((-19.9245, -43.9701), 6000)
# )

# #Formatando dados genéricos
# raio_maximo = 3000
# bairros_i = [k for k in keys(bairros_bh)]
# indices_dist = [(k, j) for k in bairros_i for j in bairros_i]
# matriz_dist = Dict(p => haversine(bairros_bh[p[1]][1], bairros_bh[p[2]][1]) for p in indices_dist)
# conjunto_N = Dict(i => [k for k in bairros_i if matriz_dist[i,k] <= raio_maximo] for i in bairros_i)
# Demanda_Bairro = Dict(i => bairros_bh[2] for i in bairros_bh)
# teste = [i for i in bairros_i  if contains(i, "s")]


#Criacao de dados Aula

# #matriz_distancias = [[v for v in range(1, locais_candidatos)] for i in range(1, origens)]
# matriz_distancias_aux = [[98,50,93,90,70],
#                     [86,52,84,84,86],
#                     [62,31,47,87,68],
#                     [32,52,33,81,31],
#                     [72,47,65,95,34],
#                     [77,37,54,46,98],
#                     [58,46,98,91,50], 
#                     [54,85,93,58,92],
#                     [47,42,95,38,43],
#                     [55,54,91,90,33]]

# D_max_aux = [79,75,75,78,76,79,75,75,77,75]
# custo_abertura_aux = [110,120,90,90,85]

origens = 10 #bairros
locais_candidatos = 5
s_origens = [i for i in range(1, origens)]#Distancias origem-destino
s_locais_candidatos = [i for i in range(1, locais_candidatos)]
#Dados 
matriz_distancias_aux = [[71,81,100,93,94], 
                        [63,55,51, 68,44],
                        [49,55,56,67,88], 
                        [38,69,55,48,66], 
                        [90,76,86,47,52],
                        [52,78,52,72,32], 
                        [64,40,73,85,57], 
                        [72,84,59,97,77], 
                        [66,76,98, 66,95], 
                        [74,100,80,66,77]]

D_max_aux = [76,79,79,75,79,79,80,78,80,75]
custo_abertura_aux = [110,120,90,90,85]


# formatando conjuntos!!
matriz_distancia = Dict((orig, loc) => matriz_distancias_aux[orig][loc] for orig in range(1,origens) for loc in range(1,locais_candidatos))
D_Max = Dict(i => D_max_aux[i] for i in range(1, origens))
custo_abertura = Dict(i => custo_abertura_aux[i] for i in range(1,locais_candidatos))
Conjunto_N = Dict(org => [loc_cand for loc_cand in range(1,locais_candidatos) if matriz_distancia[(org, loc_cand)] <= D_Max[org]] 
                            for org in range(1,origens))



model = JuMP.Model(HiGHS.Optimizer)
var_locais_candidatos = @variable(model, local_[i in s_locais_candidatos], Bin) #cada bairro é uma possível base 

@objective(model, Min, sum(local_[i] * custo_abertura[i] for i in s_locais_candidatos)) #minimizar a quantidade de bases abertas

#posso criar as restrições com loop?
#for i in bairros_i
@constraint(model, [i ∈ s_origens] , sum(local_[br] for br in Conjunto_N[i]) >= 1) 
#end

optimize!(model) 

obj = objective_value(model)
#indices_abertos = Array(value.(model[local_]))
variavel_resposta = [i for i in s_locais_candidatos  if value(var_locais_candidatos[i]) > 0]
println("Localidades abertas: $variavel_resposta")
for i in s_origens
    dist = Dict(loc => matriz_distancia[(i, loc)] for loc in variavel_resposta)
    dist_end = sort(collect(dist), by = x -> x[2])[1]
    dest_fim = dist_end[1]
    custo_end = dist_end[2]
    println("Origem $i alocada no local $dest_fim com distancia $custo_end Km ")
end




# pontos_abertos = [bairros_i[k] for k in 1:length(Array(model[:x])) if indices_abertos[k] > 0]

# latitudes_demandas = [bairros_bh[i][1][1] for i in bairros_i if  !(i in pontos_abertos)]
# longitude_demandas = [bairros_bh[i][1][2] for i in bairros_i if  !(i in pontos_abertos)]

# latitudes_pontos = [bairros_bh[i][1][1] for i in bairros_i if  (i in pontos_abertos)]
# longitude_pontos = [bairros_bh[i][1][2] for i in bairros_i if  (i in pontos_abertos)]

# fig = Figure()
# ax = Axis(fig[1, 1], title="Pontos Abertos")

# GeoMakie.scatter!(ax, longitude_demandas, latitudes_demandas, color=:blue, marker=:circle, markersize=10)
# GeoMakie.scatter!(ax, longitude_pontos, latitudes_pontos, color=:yellow, marker=:circle, markersize=10)

# display(fig)


# b=0
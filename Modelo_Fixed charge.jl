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

#Dados Input
origens = 10
locais_candidatos = 5
s_origens = [i for i in range(1, origens)]
s_locais_candidatos = [i for i in range(1, locais_candidatos)]
custo_transporte = 5

matriz_dist_aux = [
    [84, 67, 87, 41, 70],
    [47, 68, 63, 85, 53],
    [46, 98, 46, 92, 84],
    [80, 40, 48, 65, 79],
    [36, 91, 44, 86, 69],
    [39, 92, 85, 58, 75],
    [95, 45, 69, 90, 43],
    [48, 39, 94, 100, 51],
    [90, 40, 56, 92, 86],
    [94, 62, 37, 83, 35]
]

demanda_origem_aux = [35,43,64,50,84,53,45,46,66,43]
custo_abertura_aux = [98,88,100,102,79]
capacidade_aux = [254,190,189,191,131]

#Formatando dicts para o modelo!

matriz_dist = Dict((i,j) => matriz_dist_aux[i][j] for i in s_origens for j in s_locais_candidatos)
demanda = Dict(i => demanda_origem_aux[i] for i ∈ s_origens)
custo_abertura = Dict(i => custo_abertura_aux[i] for i in s_locais_candidatos)
capacidade = Dict(i => capacidade_aux[i] for i in s_locais_candidatos)



model = JuMP.Model(HiGHS.Optimizer)

#Variavel de abertura de facilidade!!
@variable(model, facilitie_[i ∈ s_locais_candidatos], Bin)

#Variável de atribuição
@variable(model, atr[i ∈ s_origens, j ∈ s_locais_candidatos], Bin)

#Função Objetivo!!
#Treinando usar o expression para organizar melhor o código!!

#Expressão do Custo abertura de facilidade!
@expression(model, custo_abertura_facilidade, sum(facilitie_[j] * custo_abertura[j] for j in s_locais_candidatos))

#Expressao do Custo de atendimento da demanda!
@expression(model, custo_atendimento_demanda, custo_transporte * sum(demanda[i] * matriz_dist[i,j] * atr[i,j] for i in s_origens for j in s_locais_candidatos))

#Funcao Objetivo
@objective(model, Min, custo_abertura_facilidade + custo_atendimento_demanda)


#Restrições
#Toda origem precisa ser atendida!
@constraint(model, [i ∈ s_origens], sum(atr[i,j] for j in s_locais_candidatos) == 1)

#Ativação da abertura se houver atribuição
@constraint(model, [i ∈ s_origens, j ∈ s_locais_candidatos], atr[i,j] <= facilitie_[j])

#Restrição de capacidade!
@constraint(model, [j ∈ s_locais_candidatos], sum(demanda[i] * atr[i,j] for i ∈ s_origens) <= capacidade[j])


#Chamando solver!
optimize!(model)

obj = objective_value(model)
pontos_abertos= [(v, value(v)) for v in Array(model[:facilitie_]) if value(v) > 0]
println("sol_plant = ", [(atr[i,j], value(atr[i,j])) for i in s_origens for j in s_locais_candidatos if value(atr[i,j]) > 0])
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


matriz_distancias_aux = [
    [76, 78, 80, 57, 82],
    [60, 49, 34, 62, 73],
    [68, 35, 32, 44, 81],
    [84, 58, 46, 44, 63],
    [64, 81, 94, 78, 47],
    [72, 91, 65, 65, 34],
    [88, 33, 49, 40, 61],
    [30, 87, 48, 94, 64],
    [38, 42, 57, 72, 64],
    [88, 93, 58, 83, 79]
]

demanda_aux = [54,26,48,70,63,71,50,33,42,53]



#Preparação dos dados
origens = 10 #bairros
locais_candidatos = 5
s_origens = [i for i in range(1, origens)]#Distancias origem-destino
s_locais_candidatos = [i for i in range(1, locais_candidatos)]
n_facilidades = 3

#
matriz_distancia = Dict((orig, loc) => matriz_distancias_aux[orig][loc] for orig in range(1,origens) for loc in range(1,locais_candidatos))
D_Max = Dict(i => D_max_aux[i] for i in range(1, origens))
custo_abertura = Dict(i => custo_abertura_aux[i] for i in range(1,locais_candidatos))

Demanda_input  = Dict(i => demanda_aux[i] for i in s_origens)




model = JuMP.Model(HiGHS.Optimizer)

#Variaveis

@variable(model, facilitie_[i ∈ s_origens], Bin)


@variable(model, atr[i ∈ s_origens, j ∈ s_locais_candidatos], Bin)

#Treino para expression
@expression(model, custo_fo, sum(atr[i,j] * matriz_distancia[i,j] * Demanda_input[i] for i ∈ s_origens for j ∈ s_locais_candidatos))


@objective(model, Min, custo_fo)


@constraint(model, [i ∈ s_origens], sum(atr[i,j] for j in s_locais_candidatos) == 1)


@constraint(model, sum(facilitie_[i] for i in s_locais_candidatos) == n_facilidades)


@constraint(model, [i ∈ s_origens, j ∈ s_locais_candidatos], atr[i,j] <= facilitie_[j])

optimize!(model)


obj = objective_value(model)
#pontos Abertos - Parece que a formulação nao gera inteira
pontos_abertos= [(v, value(v)) for v in Array(model[:facilitie_]) if value(v) > 0]
println("sol_plant = ", [(atr[i,j], value(atr[i,j])) for i in S_Bairros for j in conjunto_N[i] if value(atr[i,j]) > 0])
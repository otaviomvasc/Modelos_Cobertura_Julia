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



origens = 10 #bairros
locais_candidatos = 5
s_origens = [i for i in range(1, origens)]#Distancias origem-destino
s_locais_candidatos = [i for i in range(1, locais_candidatos)]
n_facilidades = 2

matriz_distancias_aux = [   [93, 56, 46, 98, 52],
                            [96, 44, 44, 93, 89],
                            [34, 52, 91, 56, 99],
                            [54, 66, 63, 75, 83],
                            [93, 57, 94, 92, 82],
                            [66, 46, 65, 78, 43],
                            [96, 46, 94, 30, 91],
                            [64, 81, 97, 81, 97],
                            [89, 48, 84, 68, 42],
                            [82, 34, 52, 73, 93]]

D_max_aux = [75,79,80,76,80,77,79,76,76,79]
custo_abertura_aux = [110,120,90,90,85]
demanda_aux = [50,60,52,50,37,58,51,37,44,36]

#Criação dos dicionarios do modelo!
matriz_distancia = Dict((orig, loc) => matriz_distancias_aux[orig][loc] for orig in range(1,origens) for loc in range(1,locais_candidatos))
D_Max = Dict(i => D_max_aux[i] for i in range(1, origens))
custo_abertura = Dict(i => custo_abertura_aux[i] for i in range(1,locais_candidatos))
Conjunto_N = Dict(org => [loc_cand for loc_cand in range(1,locais_candidatos) if matriz_distancia[(org, loc_cand)] <= D_Max[org]] 
                            for org in range(1,origens))
Demanda_input  = Dict(i => demanda_aux[i] for i in s_origens)

#criação do modelo
model = JuMP.Model(HiGHS.Optimizer)

#Criacao das variáveis
#Abertura de facilidade
facilidades_abertas = @variable(model, facilitie_[i ∈ s_locais_candidatos], Bin)

#Atribuicao de demanda em facilidade
atribuicao = @variable(model, atr[d ∈ s_origens, b ∈ Conjunto_N[d]], Bin)

#Variável auxiliar para guardar maior distância!
@variable(model, L >= 0)

#Função Objetivo
@objective(model, Min, L)


#Toda demanda precisa ser atribuida!!
@constraint(model, [i ∈ s_origens], sum(atr[i,j] for j in Conjunto_N[i]) == 1)

#Numero facilidades
@constraint(model, sum(facilitie_[i] for i in s_locais_candidatos) == n_facilidades)

#Teste de funcionamento do dominio
#@constraint(model, [i ∈ S_Bairros], sum(facilitie_[i]) == n_facilidades)

#Definicao da variável Lista - #TODO: Tenho que inserir o tempo de deslocamento
@constraint(model, [i ∈ s_origens], sum(Demanda_input[i] * matriz_distancia[i,j] * atr[i, j] for j in Conjunto_N[i]) <= L )

#Atribuicao de demanda a facilidade!!
@constraint(model, [i ∈ s_origens, j ∈ Conjunto_N[i]], atr[i,j] <= facilitie_[j])


#Rodada do modelo!!
print(model)
optimize!(model)

obj = objective_value(model)
#pontos Abertos - Parece que a formulação nao gera inteira
locais_abertos = [(i, value(facilidades_abertas[i])) for i in s_locais_candidatos if value(facilidades_abertas[i]) > 0]

atribuicoes_fim = [(i,j) for i in s_origens for j in Conjunto_N[i] if value(atribuicao[i,j]) > 0]

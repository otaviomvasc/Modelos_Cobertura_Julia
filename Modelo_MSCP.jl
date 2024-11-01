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


#Lista de bairros de belo horizonte
#lista de bairros, com 0 sendo latitude e longitude e 1 a estimativa da população!!
bairros_bh = Dict(
    "Afonso Pena" => ((-19.9345, -43.9343), 10000),  # Exemplo: 10.000 pessoas
    "Alto Barroca" => ((-19.9378, -43.9311), 8000),
    "Alto Santa Lúcia" => ((-19.9342, -43.9830), 5000),
    "Barroca" => ((-19.9339, -43.9385), 7000),
    "Bela Vista" => ((-19.9335, -43.9350), 12000),
    "Buritis" => ((-19.9725, -43.9613), 15000),
    "Centro" => ((-19.9301, -43.9378), 20000),
    "Cidade Nova" => ((-19.9199, -43.9325), 11000),
    "Dom Silvério" => ((-19.9097, -43.9581), 3000),
    "Funcionários" => ((-19.9350, -43.9362), 9000),
    "Gameleira" => ((-19.9704, -43.9749), 4000),
    "Horto" => ((-19.9359, -43.9488), 2500),
    "Lourdes" => ((-19.9352, -43.9354), 7000),
    "Savassi" => ((-19.9380, -43.9331), 15000),
    "São Pedro" => ((-19.9313, -43.9412), 5000),
    "Sion" => ((-19.9523, -43.9386), 6000),
    "Santa Efigênia" => ((-19.9367, -43.9323), 8000),
    "Estoril" => ((-19.9743, -43.9636), 4000),
    "Belvedere" => ((-19.9604, -43.9565), 10000),
    "Nova Suíça" => ((-19.9330, -43.9330), 9000),
    "Palmeiras" => ((-19.9433, -43.9490), 11000),
    "Vila da Serra" => ((-19.9581, -43.9523), 3000),
    "São Lucas" => ((-19.9518, -43.9479), 2000),
    "Coração Eucarístico" => ((-19.8856, -43.9431), 1500),
    "Caiçara" => ((-19.9245, -43.9701), 6000)
)

#Preparação dos dados
#Criacao de dados Aula





matriz_distancias_aux = [[89,98,90,76,53],
                        [45,96,	67,	74,	52],
                        [82,92,	52,	89,	90],
                        [100,57,47,40,74],
                        [57,52,	76,	53,	43],
                        [64,38,	47,	44,	58],
                        [38,42,	69,	52,	37],
                        [92,35,	99,	60,	81],
                        [60,83,	69,	50,	55],
                        [32,58,	75,	49,	64]
                        ]

D_max_aux = [76,75,75,75,80,79,75,9,76,80]
demanda_aux = [59,46,35,61,48,68,67,48,63,69]
custo_abertura_aux = [110,120,90,90,85]


origens = 10 #bairros
locais_candidatos = 5
s_origens = [i for i in range(1, origens)]#Distancias origem-destino
s_locais_candidatos = [i for i in range(1, locais_candidatos)]
n_facilidades = 2



#Criação dos dicionarios do modelo!
matriz_distancia = Dict((orig, loc) => matriz_distancias_aux[orig][loc] for orig in range(1,origens) for loc in range(1,locais_candidatos))
D_Max = Dict(i => D_max_aux[i] for i in range(1, origens))
custo_abertura = Dict(i => custo_abertura_aux[i] for i in range(1,locais_candidatos))
Conjunto_N = Dict(org => [loc_cand for loc_cand in range(1,locais_candidatos) if matriz_distancia[(org, loc_cand)] <= D_Max[org]] 
                            for org in range(1,origens))
Demanda_input  = Dict(i => demanda_aux[i] for i in s_origens)


#Criação dos modelos
model = JuMP.Model(HiGHS.Optimizer)

#Criação das variáveis - x
var_facilities = @variable(model, facilitie_[i ∈ s_locais_candidatos], Bin)

#varivel que indica se a demanda D é atendida - z
var_end_demanda = @variable(model, var_demanda_[i ∈ s_origens], Bin)

#Funcao Objetivo!!

@objective(model, Max, sum(Demanda_input[i] * var_demanda_[i] for i ∈ s_origens))

#Restrições:
#Total de abertura de facilidades!

@constraint(model, sum(facilitie_[i] for i ∈ s_locais_candidatos) == n_facilidades)


#Demanda atendida apenas se tiver facilidades - #Segundo argumento faz o papel do for. Testar para ver se ambos ficam iguais!!!
@constraint(model, [i ∈ s_origens], var_demanda_[i] <= sum(facilitie_[k] for k ∈ Conjunto_N[i]))

optimize!(model)


obj = objective_value(model)
println("Função Objeto: $obj")
#Locais Abertos
locais_abertos = [i for i in s_locais_candidatos  if value(var_facilities[i]) > 0]
#println("------------------------------------------------")
println("Locais abertos: $locais_abertos")
#demandas_atendidas
demandas_atendidas = [i for i in s_origens  if value(var_end_demanda[i]) > 0]
#println("------------------------------------------------")
println("Demandas atendidas: $demandas_atendidas")
demandas_nao_atendidas = [i for i in s_origens  if value(var_end_demanda[i]) == 0]
#println("------------------------------------------------")
println("Demandas NÂO Atendidas: $demandas_nao_atendidas")

#total_demandas
demanda_total = sum(Demanda_input[i] for i ∈ s_origens)

#Cobertura!
cobertura_atingida = obj/demanda_total
#println("------------------------------------------------")
println("Cobertura atingida: $cobertura_atingida")
#println("------------------------------------------------")
println("Alocações:")



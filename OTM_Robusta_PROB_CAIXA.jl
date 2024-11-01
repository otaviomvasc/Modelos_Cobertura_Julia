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
using LinearAlgebra
using Distributions 
using SCS


Random.seed!(1234);

#Primeira tentativa de fazer o problema da mochila robusto
function gerador_dados_brutos(max_param, intervalo_dados, qntd_dados=50)
    #gerar dados
    #calcular Nij
    #filtrar dados fora do Nij
    #Corrigir media e desvio
    #retornar desv_pad e media!!
    dados_brutos = rand(intervalo_dados[1]:intervalo_dados[2], qntd_dados)
    md_aux = median(dados_brutos)
    max_deviation = maximum(dados_brutos) - md_aux
    Nij = [(v - md_aux) / max_deviation for v in dados_brutos]
    max_dev = maximum([dados_brutos[v] - md_aux for v in range(1, qntd_dados) if abs(Nij[v]) <= max_param])
    return Dict("Media" => md_aux, "max_dev" => max_dev)

end

#TODO: CRIAR MÉTODO EXCLUSIVO PARA CORRIGIR DEVIDO FATOR EXTERNO!!

function gerador_dist_normal(max_param, intervalo_dados, desv_pad, qntd_dados=50)

    media = rand(intervalo_dados[1]:intervalo_dados[2])
    peso_st = media * desv_pad

    #gerando dados via normal
    dados_peso = rand(Normal(media, peso_st), qntd_dados)
    md_aux = median(dados_peso)
    max_deviation = maximum(dados_peso) - md_aux
    Nij = [(v - md_aux) / max_deviation for v in dados_peso]
    max_dev = maximum([dados_peso[v] - md_aux for v in range(1, qntd_dados) if abs(Nij[v]) <= max_param])
    return Dict("Media" => md_aux, "max_dev" => max_dev)



end


#Geracao_dados_elipsoide
function gerador_dados_brutos_elipsoide(intervalo_dados,qntd_dados=50)

    dados_brutos = rand(intervalo_dados[1]:intervalo_dados[2], qntd_dados)
    md_aux = median(dados_brutos)
    max_deviation = maximum(dados_brutos) - md_aux
    #Nij = [(v - md_aux) / max_deviation for v in dados_brutos]
    return Dict("Media" => md_aux, "max_dev" => max_deviation)

end


#Setando dos dados!
n_itens = 5000000
qntd_dados = 300
range_itens = range(1,n_itens)
Γ = 1  #Viabilidade em 80% dos itens!! Coef de risco!!
intervalo_dados = (10,25)
desvio = 2
dados = Dict()

#Criando dados!!

dados_1 = Dict(item => gerador_dados_brutos(Γ, intervalo_dados, qntd_dados) for item in range_itens)
dados_2 = Dict(item => gerador_dist_normal(Γ, intervalo_dados, desvio, qntd_dados) for item in range_itens)
dados_elipsoide = Dict(item => gerador_dados_brutos_elipsoide(intervalo_dados,  qntd_dados) for item in range_itens)


# Dados gerais!!
cap_mochila = ceil(mean([dados_2[i]["Media"] for i in range_itens]) * n_itens * 0.5) #Escolha de mais ou menos metade dos itens!!
valor_item = Dict(i => rand(5:15,1)[1] for i in range_itens)

#Criação do Modelo!!!
P = diagm([dados_2[k]["max_dev"] for k in range_itens ])
model = JuMP.Model(HiGHS.Optimizer)

#Criando variavel do item!!

@variable(model, x[i:n_itens], Bin)

@objective(model, Max, sum(x[i] * valor_item[i] for i in range_itens))

#Restrição de capacidade - Tratei o apetite ao risco no pre-processamento. Somar valores antes também???

#Correção do valor da média pelo desvio máximo de acordo com um fator de correção do Nij!!!
#Restrição para incerteza da caixa!

@constraint(model, sum((dados_1[j]["Media"] + dados_1[j]["max_dev"]) * x[j] for j in range_itens) <= cap_mochila)

#Restrição para elipsoide!! - Não tem como fazer cone de segunda ordem com solver HiGHS. 
#Quanto tentei trocar o solver para um que parece aceitar, não aceita variável binaria

#@expression(model, t, (cap_mochila - sum(dados_1[j]["Media"] * x[j] for j = 1:N)))
#@constraint(model, [t; Γ .* (P * x)])

#chama solver!!!
optimize!(model)


#valor da FO:
obj = println(objective_value(model))
itens_escolhidos = [var for var in model[:x] if value(var) > 0]


using Pkg
Pkg.add("GLM")

using XLSX, DataFrames
using StatsKit

df = DataFrame(XLSX.readtable("DEA_VariaveisAmbientais.xlsx", "Sheet 1"))

println(names(df))
colunas_regressao = [
                "PrecipMedAnualMed","DensFocQueim",
                "DeclMedPerc","AltMedVeg",
                "FocQueim","DescAtmMed",
                "TempMedAn","UnidCons_TI",
                "PercEstraPavQA","PercEstraPavIN"]
    

col_target = "DEA.Media21"
colunas  = names(df)
y = float.(df[!, "DEA.Media21"])
lista_modelos = Dict()
for col in colunas_regressao
    #Testes para resolver o problema, mas descobrir como fazer isso de forma melhor!!
    x = float.(df[!, col])
    df_aux = DataFrame(x = x, y = y)
    modelo = lm(@formula(y ~ x), df_aux)
    println(modelo)   # Coeficientes da regressão
    #println(modelo)
    lista_modelos[col] = modelo    
end



# main.R - Executa o pipeline completo do projeto

cat("1/4 Executando Limpeza de Dados...\n")
source("R/00_limpeza_dados.R")

cat("2/4 Executando Análise de Perfil de Risco...\n")
source("R/01_eda_perfil_risco.R")

cat("3/4 Executando Precificação e Spreads...\n")
source("R/02_precificacao.R")

cat("4/4 Gerando Matriz de Risco...\n")
source("R/03_matriz_risco.R")

cat("Pipeline concluído com sucesso!\n")
# ==============================================================================
# PROJETO: Análise e Modelagem de Risco de Crédito
# SCRIPT: 00_limpeza_dados.R
# OBJETIVO: Carga, análise de nulos, imputação estocástica e exportação
# AUTOR: Claudio Graca
# ==============================================================================

# 1. Pacotes -------------------------------------------------------------------
library(tidyverse)

# 2. Leitura / Download dos Dados Brutos --------------------------------------
raw_dir <- "data/raw"
raw_file_path <- file.path(raw_dir, "Loan_Default.csv")

# Cria a pasta caso não exista
if (!dir.exists(raw_dir)) {
  dir.create(raw_dir, recursive = TRUE)
}

# Se o arquivo não existir localmente, faz o download
if (!file.exists(raw_file_path)) {
  cat("-> Arquivo de dados não encontrado localmente. Baixando da nuvem...\n")
  
  # URL do dataset do kaggle
  url_data <- "https://www.kaggle.com/api/v1/datasets/download/yasserh/loan-default-dataset"
  
  download.file(url_data, destfile = raw_file_path, mode = "wb")
  cat("-> Download concluído com sucesso!\n\n")
}

Loan_Default <- read_csv(raw_file_path, show_col_types = FALSE)

cat("-> Dataset carregado com sucesso:", nrow(Loan_Default), "linhas e", ncol(Loan_Default), "colunas.\n\n")

# 3. Dicionário Operacional das Categoriatórias (Referência) --------------------
# loan_limit: cf (credit facility) | ncf (non credit facility)
# gender: Male | Female | Joint | Sex not available
# approv_in_adv: nopre (sem pré-aprovação) | pre (pré-aprovado)
# loan_type: type1 (convencional) | type2 (FHA insured) | type3 (VA guaranteed)
# loan_purpose: p1 (home purchase) | p2 (home improvement) | p3 (infra) | p4 (outro)
# credit_worthiness: l1 (baixo/sem risco) | l2 (risco baixo a moderado)
# open_credit: nopc (não) | opc (sim)
# business_or_commercial: nob/c (não comercial) | b/c (comercial)
# neg_ammortization: not_neg | neg_amm
# interest_only: not_int | int_only
# lump_sum_payment: not_ipsm | ipsm
# construction_type: sb (site built) | mh (manufactured home)
# occupancy_type: pr (residência principal) | ir (investimento) | sr (secundária)
# secured_by: home | land
# total_units: 1U | 2U | 3U | 4U
# credit_type: CIB (TransUnion CIBIL) | CRIF | EXP (Experian) | EQUI (Equifax)
# submission_of_application: to_inst | not_inst
# Region: North | South | Central | North-East
# security_type: direct | indirect

# 4. Análise Exploratória de Ausentes (Nulos) -----------------------------------
cat("=== DIAGNÓSTICO INICIAL DE DADOS AUSENTES ===\n")

null_analytics <- data.frame(
  variavel = names(Loan_Default),
  n_nulos  = colSums(is.na(Loan_Default)),
  pct_nulos = (colSums(is.na(Loan_Default)) / nrow(Loan_Default)) * 100,
  row.names = NULL
) %>% 
  arrange(desc(pct_nulos))

print(head(null_analytics, 15))

# 5. Funções Auxiliares de Imputação ------------------------------------------
# Funcao para Imputacao por Amostragem Aleatoria Simples (Sample Input)
# Preenche valores NA amostrando diretamente dos valores observados na variavel.
# Preserva a distribuicao empirica e a variancia original da coluna.
sample_input <- function(x) {
  na_mask <- is.na(x)
  if (any(na_mask)) {
    x[na_mask] <- sample(na.omit(x), size = sum(na_mask), replace = TRUE)
  }
  return(x)
}

# 6. Pipeline de Higienização e Trata de Nulos ---------------------------------
cat("\nExecuting pipeline de limpeza e imputação...\n")

clean_data_loan <- Loan_Default %>% 
  # Remoção de NAs em variáveis críticas cadastrais e categóricas estruturais
  drop_na(
    loan_limit, approv_in_adv, loan_purpose, term, 
    Neg_ammortization, age, submission_of_application, income
  ) %>% 
  # Imputação estocástica via sample_input para métricas financeiras contínuas
  mutate(across(
    c(rate_of_interest, Interest_rate_spread, Upfront_charges, property_value, LTV, dtir1),
    sample_input
  ))

# 7. Validação Pós-Limpeza -----------------------------------------------------
cat("\n=== DIAGNÓSTICO PÓS-LIMPEZA ===\n")

clean_null_analytics <- data.frame(
  variavel = names(clean_data_loan),
  n_nulos  = colSums(is.na(clean_data_loan)),
  pct_nulos = (colSums(is.na(clean_data_loan)) / nrow(clean_data_loan)) * 100,
  row.names = NULL
)

cat("Total de NAs restantes no dataset:", sum(clean_null_analytics$n_nulos), "\n")
cat("Total de observações mantidas:", nrow(clean_data_loan), 
    paste0("(", round((nrow(clean_data_loan) / nrow(Loan_Default)) * 100, 2), "% da base original)\n\n"))

# 8. Exportação do Dataset Processado -------------------------------------------
output_dir <- "data/processed"

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_path <- file.path(output_dir, "Loan_Data.csv")

write_csv(clean_data_loan, output_path)

cat("-> Dataset higienizado exportado com sucesso para:", output_path, "\n")
cat("=== SCRIPT 00 FINALIZADO COM SUCESSO ===\n")

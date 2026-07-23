# ==============================================================================
# PROJETO: Análise de Risco de Crédito (Loan Default)
# ETAPA: 2.B - Testes de Hipótese Estatísticos
# ARQUIVO: R/04_testes_hipotese.R
# AUTOR: Claudio Graca
# ==============================================================================

library(tidyverse)


cat("\n==================================================================\n")
cat("      1. TESTE DE MANN-WHITNEY (Diferença de Distribuições)        \n")
cat("==================================================================\n")

# Funcao auxiliar para executar Wilcoxon/Mann-Whitney em variaveis numericas
testar_numerica <- function(df, var_nome) {
  formula_teste <- as.formula(paste(var_nome, "~ Status"))
  teste <- wilcox.test(formula_teste, data = df)
  
  mediana_adimplente <- median(df[[var_nome]][df$Status == 0], na.rm = TRUE)
  mediana_inadimplente <- median(df[[var_nome]][df$Status == 1], na.rm = TRUE)
  
  cat(sprintf("\nVariável Analisada: [%s]\n", var_nome))
  cat(sprintf(" - Mediana Adimplente (0)  : %.2f\n", mediana_adimplente))
  cat(sprintf(" - Mediana Inadimplente (1): %.2f\n", mediana_inadimplente))
  cat(sprintf(" - p-valor do Teste        : %.5e\n", teste$p.value))
  
  if (teste$p.value < 0.05) {
    cat(" - Conclusão: DIFERENÇA ESTATISTICAMENTE SIGNIFICATIVA (Rejeita H0 ao nível de 5%)\n")
  } else {
    cat(" - Conclusão: Não há evidência suficiente de diferença (Falha em rejeitar H0)\n")
  }
}

# Testando os 3 principais pilares financeiros
testar_numerica(Loan_Data, "dtir1")       # Comprometimento de Renda
testar_numerica(Loan_Data, "LTV")         # Loan-to-Value
testar_numerica(Loan_Data, "income")      # Renda Bruta


cat("\n==================================================================\n")
cat("      2. TESTE QUI-QUADRADO DE INDEPENDÊNCIA (Categorias)          \n")
cat("==================================================================\n")

# Funcao auxiliar para Qui-Quadrado em variaveis categoricas
testar_categorica <- function(df, var_nome) {
  tabela_contingencia <- table(df[[var_nome]], df$Status)
  teste_chi2 <- chisq.test(tabela_contingencia)
  
  cat(sprintf("\nVariável Categorizada: [%s]\n", var_nome))
  cat(sprintf(" - Estatística Qui-Quadrado (X2): %.2f\n", teste_chi2$statistic))
  cat(sprintf(" - p-valor do Teste            : %.5e\n", teste_chi2$p.value))
  
  if (teste_chi2$p.value < 0.05) {
    cat(" - Conclusão: ASSOCIAÇÃO SIGNIFICATIVA com a Inadimplência (Rejeita H0 ao nível de 5%)\n")
  } else {
    cat(" - Conclusão: Inadimplência INDEPENDENTE desta variável (Falha em rejeitar H0)\n")
  }
}

# Testando fatores de perfil e garantia
testar_categorica(Loan_Data, "occupancy_type") # Uso do Imóvel (Residencial/Investimento)
testar_categorica(Loan_Data, "credit_type")    # Tipo de Crédito/Score
testar_categorica(Loan_Data, "Region")         # Região Geográfica
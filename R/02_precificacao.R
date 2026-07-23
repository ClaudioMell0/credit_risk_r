# ==============================================================================
# PROJETO: Análise de Risco de Crédito (Loan Default)
# ETAPA: 1.B - Precificação e Margem (Juros e Spreads)
# ARQUIVO: R/02_precificacao.R
# AUTOR: Claudio Graca
# ==============================================================================

library(tidyverse)

# ------------------------------------------------------------------------------
# 1. Resumo das Taxas e Spreads por Status de Inadimplência
# ------------------------------------------------------------------------------
cat("\n--- 1. RESUMO DE TAXAS E SPREADS POR STATUS ---\n")

precificacao_status <- Loan_Data |> 
  group_by(Status_label) |> 
  summarise(
    Contratos = n(),
    Juros_Medio = round(mean(rate_of_interest, na.rm = TRUE), 3),
    Juros_Mediano = round(median(rate_of_interest, na.rm = TRUE), 3),
    Spread_Medio = round(mean(Interest_rate_spread, na.rm = TRUE), 3),
    Upfront_Medio = round(mean(Upfront_charges, na.rm = TRUE), 2)
  )

print(precificacao_status)

# ------------------------------------------------------------------------------
# 2. Precificação Baseada em Risco: Score de Crédito vs. Juros Médios
# ------------------------------------------------------------------------------
cat("\n--- 2. FAIXAS DE SCORE VS. TAXA DE JUROS E DEFAULT ---\n")

# Agrupando por faixas padrão do mercado (FICO Score)
Loan_Data <- Loan_Data |> 
  mutate(faixa_score = cut(
    Credit_Score, 
    breaks = c(300, 580, 670, 740, 800, 900),
    labels = c("Muito Baixo (300-580)", "Baixo (581-670)", "Médio (671-740)", "Bom (741-800)", "Excelente (>800)")
  ))

score_precificacao <- Loan_Data |> 
  group_by(faixa_score) |> 
  summarise(
    Contratos = n(),
    Juros_Medio = round(mean(rate_of_interest, na.rm = TRUE), 2),
    Spread_Medio = round(mean(Interest_rate_spread, na.rm = TRUE), 2),
    Taxa_Default_Pct = round(mean(Status == 1) * 100, 2)
  )

print(score_precificacao)

# Gráfico 1: Relação entre Score, Taxa de Juros e Default
g_score <- ggplot(score_precificacao, aes(x = faixa_score, y = Juros_Medio, group = 1)) +
  geom_col(fill = "#2b5c8f", width = 0.5, alpha = 0.8) +
  geom_text(aes(label = paste0(Juros_Medio, "%")), vjust = -0.5, fontface = "bold") +
  scale_y_continuous(limits = c(0, max(score_precificacao$Juros_Medio, na.rm = TRUE) * 1.25)) +
  labs(
    title = "Taxa Média de Juros por Faixa de Score de Crédito",
    subtitle = "Avaliação da aderência do modelo de Risk-Based Pricing",
    x = "Faixa de Score de Crédito",
    y = "Taxa de Juros Média (%)"
  ) +
  theme_minimal()

print(g_score)

# ------------------------------------------------------------------------------
# 3. Distribuição do Spread de Juros por Status (Boxplot)
# ------------------------------------------------------------------------------
g_spread <- ggplot(Loan_Data, aes(x = Status_label, y = Interest_rate_spread, fill = Status_label)) +
  geom_boxplot(alpha = 0.7, outlier.color = "gray60", outlier.alpha = 0.3) +
  scale_fill_manual(values = c("Adimplente" = "#2b5c8f", "Inadimplente" = "#d95f02")) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(
    title = "Distribuição do Spread de Juros por Status",
    subtitle = "Inadimplentes pagaram spreads maiores na contratação?",
    x = "Status do Cliente",
    y = "Spread da Taxa de Juros"
  )

print(g_spread)
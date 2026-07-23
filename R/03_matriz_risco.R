# ==============================================================================
# PROJETO: Análise de Risco de Crédito (Loan Default)
# ETAPA: 2.A - Matriz de Risco Bidimensional (DTI vs. LTV)
# ARQUIVO: R/03_matriz_risco.R
# AUTOR: Claudio Graca
# ==============================================================================

library(tidyverse)

# ------------------------------------------------------------------------------
# 1. Categorização em Faixas Estratégicas de Mercado
# ------------------------------------------------------------------------------
Loan_Data <- Loan_Data |> 
  mutate(
    # Faixas de DTI (Comprometimento da Renda)
    faixa_DTI = cut(
      dtir1,
      breaks = c(-Inf, 36, 45, Inf),
      labels = c("Saudável (<=36%)", "Moderado (36-45%)", "Crítico (>45%)")
    ),
    # Faixas de LTV (Risco da Garantia/Imóvel)
    faixa_LTV = cut(
      LTV,
      breaks = c(-Inf, 70, 85, Inf),
      labels = c("Baixo (<=70%)", "Médio (70-85%)", "Alto (>85%)")
    )
  )

# ------------------------------------------------------------------------------
# 2. Agregação para Construção da Matriz
# ------------------------------------------------------------------------------
cat("\n--- MATRIZ DE RISCO: TAXA DE DEFAULT POR QUADRANTE (%)\n")

matriz_risco <- Loan_Data |> 
  filter(!is.na(faixa_DTI), !is.na(faixa_LTV)) |> 
  group_by(faixa_LTV, faixa_DTI) |> 
  summarise(
    Total_Contratos = n(),
    Qtd_Default = sum(Status == 1),
    Taxa_Default_Pct = round(mean(Status == 1) * 100, 2),
    .groups = "drop"
  )

print(matriz_risco)

# ------------------------------------------------------------------------------
# 3. Visualização: Heatmap de Risco (Matriz DTI x LTV)
# ------------------------------------------------------------------------------
g_matriz <- ggplot(matriz_risco, aes(x = faixa_DTI, y = faixa_LTV, fill = Taxa_Default_Pct)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(
    aes(label = paste0(Taxa_Default_Pct, "%\n(", Total_Contratos, " oper.)")),
    color = "black", 
    size = 4, 
    fontface = "bold"
  ) +
  scale_fill_gradient(
    low = "#e0f3f8", 
    high = "#d73027", 
    name = "Taxa de\nDefault (%)"
  ) +
  labs(
    title = "Matriz de Risco de Crédito: DTI vs. LTV",
    subtitle = "Identificação de quadrantes críticos de inadimplência (Comprometimento de Renda x Garantia)",
    x = "DTI - Comprometimento de Renda (Debt-to-Income)",
    y = "LTV - Proporção Financiada (Loan-to-Value)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid = element_blank(),
    axis.text = element_text(face = "bold")
  )

print(g_matriz)
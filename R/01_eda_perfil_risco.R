# ==============================================================================
# PROJETO: Análise de Risco de Crédito (Loan Default)
# ETAPA: 1.A - Perfil de Risco e Inadimplência
# ARQUIVO: R/01_eda_perfil_risco.R
# AUTOR: Claudio Graca
# ==============================================================================

library(tidyverse)
library(scales)
Loan_Data <- read.csv("data/processed/Loan_Data.csv")

# Ajuste de tema global do ggplot2
theme_set(theme_minimal(base_size = 12) + 
            theme(panel.grid.minor = element_blank(),
                  plot.title = element_text(face = "bold", size = 14),
                  plot.subtitle = element_text(color = "gray30")))

# Define paleta de cores para adimplente (Azul) vs inadimplente (Vermelho)
cores_status <- c("0" = "#2b5c8f", "1" = "#d95f02")

# ------------------------------------------------------------------------------
# 1. Validar e Entender a Variável Alvo (`Status`)
# ------------------------------------------------------------------------------
cat("\n--- 1. RESUMO DA VARIÁVEL ALVO (STATUS) ---\n")

# Ajusta o Status para Fator se necessário (0 = Adimplente, 1 = Inadimplente)
Loan_Data <- Loan_Data |> 
  mutate(Status_label = factor(Status, levels = c(0, 1), labels = c("Adimplente", "Inadimplente")))

resumo_status <- Loan_Data |> 
  group_by(Status_label) |> 
  summarise(
    Total = n(),
    Percentual = (n() / nrow(Loan_Data)) * 100
  )

print(resumo_status)

# ------------------------------------------------------------------------------
# 2. Taxa de Inadimplência por Variáveis Categóricas Chave
# ------------------------------------------------------------------------------
cat("\n--- 2. TAXA DE DEFAULT POR PROPÓSITO DO EMPRÉSTIMO ---\n")

default_proposito <- Loan_Data |> 
  group_by(loan_purpose) |> 
  summarise(
    Total_Contratos = n(),
    Qtd_Default = sum(Status == 1),
    Taxa_Default_Pct = round(mean(Status == 1) * 100, 2)
  ) |> 
  arrange(desc(Taxa_Default_Pct))

print(default_proposito)

# Gráfico 1: Inadimplência por Propósito
g1 <- ggplot(default_proposito, aes(x = reorder(loan_purpose, Taxa_Default_Pct), y = Taxa_Default_Pct)) +
  geom_col(fill = "#d95f02", width = 0.6) +
  geom_text(aes(label = paste0(Taxa_Default_Pct, "%")), hjust = -0.1, size = 3.5) +
  coord_flip() +
  scale_y_continuous(limits = c(0, max(default_proposito$Taxa_Default_Pct) * 1.15)) +
  labs(
    title = "Taxa de Inadimplência por Propósito do Empréstimo",
    subtitle = "Identificação de categorias com maior risco de calote",
    x = "Propósito do Empréstimo",
    y = "Taxa de Inadimplência (%)"
  )

print(g1)

# ------------------------------------------------------------------------------
# 3. Análise dos Indicadores Chave de Risco (DTI e LTV)
# ------------------------------------------------------------------------------
cat("\n--- 3. COMPARATIVO DE MÉDIAS E MEDIANAS (DTI & LTV) ---\n")

resumo_metricas <- Loan_Data |> 
  group_by(Status_label) |> 
  summarise(
    Média_DTI = round(mean(dtir1, na.rm = TRUE), 2),
    Mediana_DTI = round(median(dtir1, na.rm = TRUE), 2),
    Média_LTV = round(mean(LTV, na.rm = TRUE), 2),
    Mediana_LTV = round(median(LTV, na.rm = TRUE), 2)
  )

print(resumo_metricas)

# Gráfico 2: Distribuição de DTI e LTV por Status (Boxplots)
g2 <- ggplot(Loan_Data, aes(x = Status_label, y = LTV, fill = Status_label)) +
  geom_boxplot(alpha = 0.7, outlier.color = "gray60", outlier.alpha = 0.3) +
  scale_fill_manual(values = c("Adimplente" = "#2b5c8f", "Inadimplente" = "#d95f02")) +
  theme(legend.position = "none") +
  labs(
    title = "Distribuição do LTV (Loan-to-Value) por Status",
    subtitle = "Inadimplentes tendem a apresentar maior proporção de financiamento em relação ao imóvel",
    x = "Status do Cliente",
    y = "LTV (%)"
  )

print(g2)

# ------------------------------------------------------------------------------
# 4. Identificar o "Ponto de Corte" do Risco (Faixas de LTV e DTI)
# ------------------------------------------------------------------------------
cat("\n--- 4. TAXA DE DEFAULT POR FAIXAS DE LTV ---\n")

# Criando faixas padrão de mercado para LTV
Loan_Data <- Loan_Data |> 
  mutate(faixa_LTV = cut(
    LTV, 
    breaks = c(-Inf, 50, 70, 85, 100, Inf),
    labels = c("Até 50%", "50% - 70%", "70% - 85%", "85% - 100%", "Acima de 100%")
  ))

faixas_ltv_resumo <- Loan_Data |> 
  group_by(faixa_LTV) |> 
  summarise(
    Total = n(),
    Taxa_Default_Pct = round(mean(Status == 1) * 100, 2)
  )

print(faixas_ltv_resumo)

# Gráfico 3: Curva de Risco por Faixa de LTV
g3 <- ggplot(faixas_ltv_resumo, aes(x = faixa_LTV, y = Taxa_Default_Pct, group = 1)) +
  geom_line(color = "#d95f02", size = 1.2) +
  geom_point(color = "#d95f02", size = 3) +
  geom_text(aes(label = paste0(Taxa_Default_Pct, "%")), vjust = -0.8, size = 3.5, fontface = "bold") +
  scale_y_continuous(limits = c(0, max(faixas_ltv_resumo$Taxa_Default_Pct) * 1.25)) +
  labs(
    title = "Evolução do Risco por Faixa de LTV",
    subtitle = "A taxa de calote escala à medida que a garantia do imóvel diminui",
    x = "Faixa de LTV (Proporção Financiada)",
    y = "Taxa de Inadimplência (%)"
  )

print(g3)
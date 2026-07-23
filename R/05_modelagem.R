# ==============================================================================
# PROJETO: Análise de Risco de Crédito (Loan Default)
# ETAPA: 2.C - Modelagem Preditiva (Regressão Logística / Credit Score)
# ARQUIVO: R/05_modelagem.R
# AUTOR: Claudio Graca
# ==============================================================================

library(tidyverse)
library(pROC)        # Para cálculo da Curva ROC e AUC
library(caret)       # Para Matriz de Confusão e divisão dos dados

# Garantir reprodutibilidade na divisão aleatória
set.seed(123)

cat("\n--- 1. DIVISÃO EM TREINO (70%) E TESTE (30%) ---\n")

# Criando os índices para amostragem estratificada mantendo a proporção de Status
index_treino <- createDataPartition(Loan_Data$Status, p = 0.70, list = FALSE)

dados_treino <- Loan_Data[index_treino, ]
dados_teste  <- Loan_Data[-index_treino, ]

cat(sprintf("Registros de Treino: %d | Registros de Teste: %d\n", 
            nrow(dados_treino), nrow(dados_teste)))

# ------------------------------------------------------------------------------
# 2. Treinamento do Modelo de Regressão Logística
# ------------------------------------------------------------------------------
cat("\n--- 2. AJUSTANDO O MODELO GLM (REGRESSÃO LOGÍSTICA) ---\n")

modelo_credito <- glm(
  Status ~ dtir1 + LTV + income + rate_of_interest + credit_type + occupancy_type,
  data = dados_treino,
  family = binomial(link = "logit")
)

# Resumo dos coeficientes e p-valores do modelo
summary(modelo_credito)

# ------------------------------------------------------------------------------
# 3. Predição no Conjunto de Teste
# ------------------------------------------------------------------------------
cat("\n--- 3. AVALIANDO PERFORMANCE EM DADOS INÉDITOS (TESTE) ---\n")

# Gerando probabilidades de default para o grupo de teste
probabilidades_teste <- predict(modelo_credito, newdata = dados_teste, type = "response")

# Criando a Curva ROC
curva_roc <- roc(dados_teste$Status, probabilidades_teste)
valor_auc <- auc(curva_roc)

cat(sprintf("\n============================================\n"))
cat(sprintf("   MÉTRICA CHAVE (AUC-ROC): %.4f           \n", valor_auc))
cat(sprintf("============================================\n"))

# Visualização da Curva ROC
plot(curva_roc, col = "#d95f02", lwd = 3, main = paste("Curva ROC - Modelo de Crédito (AUC =", round(valor_auc, 3), ")"))
grid()

# ------------------------------------------------------------------------------
# 4. Matriz de Confusão e Métricas de Classificação (Cut-off = 0.50)
# ------------------------------------------------------------------------------
cat("\n--- 4. MATRIZ DE CONFUSÃO E DESEMPENHO DO CLASSIFICADOR ---\n")

cut_off <- 0.50
classes_preditas <- factor(ifelse(probabilidades_teste > cut_off, 1, 0), levels = c(0, 1))
status_real      <- factor(dados_teste$Status, levels = c(0, 1))

matriz_confusao <- confusionMatrix(classes_preditas, status_real, positive = "1")
print(matriz_confusao)
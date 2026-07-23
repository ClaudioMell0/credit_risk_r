# 🏦 Credit Risk & Loan Default Analysis in R

[![R-Version](https://img.shields.io/badge/R-4.3%2B-blue.svg)](https://www.r-project.org/)
[![Status](https://img.shields.io/badge/Status-Conclu%C3%ADdo-brightgreen.svg)]()
[![AUC-ROC](https://img.shields.io/badge/AUC--ROC-0.784-orange.svg)]()

Um projeto end-to-end de **Análise Estatística e Modelagem Preditiva de Risco de Crédito** desenvolvido em R, focado na identificação de inadimplência (*Loan Default*) em uma carteira imobiliária de aproximadamente **150 mil contratos**.

---

## 📌 Sumário
* [Visão Geral e Problema de Negócio](#-visão-geral-e-problema-de-negócio)
* [Estrutura do Repositório](#-estrutura-do-repositório)
* [Principais Descobertas (Key Findings)](#-principais-descobertas-key-findings)
* [Matriz de Risco Bidimensional (DTI vs LTV)](#-matriz-de-risco-bidimensional-dti-vs-ltv)
* [Validação Estatística de Hipóteses](#-validação-estatística-de-hipóteses)
* [Modelo Preditivo & Performance](#-modelo-preditivo--performance)
* [Recomendações Práticas de Concessão](#-recomendações-práticas-de-concessão)
* [Como Executar o Projeto](#-como-executar-o-projeto)

---

## 🎯 Visão Geral e Problema de Negócio

Em instituições financeiras, a concessão de crédito exige o equilíbrio contínuo entre **volume de originação** e **controle de inadimplência (PDD)**. O objetivo deste projeto foi analisar os determinantes de *default* em financiamentos e construir um modelo preditivo (*Credit Score*) capaz de ranquear proponentes por risco antes da aprovação.

**Perguntas de Negócio Respondidas:**
1. Quais são as características financeiras e de garantia que melhor diferenciam adimplentes e inadimplentes?
2. Como o comprometimento de renda (**DTI**) interage com a garantia do imóvel (**LTV**) na escalada do risco?
3. É possível prever a probabilidade de inadimplência mantendo alta interpretabilidade para comitês regulatórios?

---

## 📁 Estrutura do Repositório

O projeto adota uma arquitetura modularizada, onde cada etapa do ciclo de análise e modelagem está isolada em scripts numerados e ordenados:

📁 data/
  ├── raw/                 # Dataset original (Loan_Default.csv)
  └── processed/           # Dataset limpo e imputado (Loan_Data.csv)
📁 R/                       # Scripts executáveis numerados
  ├── 00_limpeza_dados.R   # Tratamento, imputação e formatação
  ├── 01_eda_perfil_risco.R # Etapa 1.A: Perfil de Inadimplência e LTV
  ├── 02_precificacao.R     # Etapa 1.B: Análise de Juros, Spreads e Score
  ├── 03_matriz_risco.R    # Etapa 2.A: Heatmap bidimensional (DTI vs LTV)
  ├── 04_testes_hipotese.R # Etapa 2.B: Testes de hipótese (Mann-Whitney e Chi2)
  └── 05_modelagem.R       # Etapa 2.C: Regressão Logística, AUC-ROC e Matriz de Confusão
📄 main.R                   # Script Mestre que executa todo o pipeline em sequência
📄 README.md                # Documentação técnica e de negócio
📄 credit_risk_r.Rproj      # Arquivo de Projeto do RStudio

---

## 💡 Principais Descobertas (Key Findings)

* **Impacto do LTV (Loan-to-Value):** A inadimplência apresenta uma evolução não-linear à medida que a garantia do imóvel diminui. Contratos com LTV superior a **85%** demonstraram taxa de calote substancialmente superior à média da carteira.
* **Precificação Baseada em Risco (*Risk-Based Pricing*):** Identificou-se que a taxa de juros média (`rate_of_interest`) cresce progressivamente conforme cai a faixa de *Credit Score*, confirmando que o modelo de precificação atual aplica sobretaxa de risco de forma alinhada às faixas de mercado.

---

## 📊 Matriz de Risco Bidimensional (DTI vs. LTV)

A análise isolada de indicadores financeiros omite o efeito acumulado de múltiplos fatores de risco. Ao cruzar a relação dívida/renda (**DTI**) com o percentual financiado (**LTV**), mapeamos a concentração de inadimplência em um mapa de calor (*Heatmap*):

| Faixa LTV \ Faixa DTI | Saudável (<= 36%) | Moderado (36% - 45%) | Crítico (> 45%) |
|---|:---:|:---:|:---:|
| **Baixo (<= 70%)** | Baixo Risco | Risco Moderado | Risco Moderado |
| **Médio (70% - 85%)** | Risco Moderado | Risco Elevação | Alto Risco |
| **Alto (> 85%)** | Risco Elevação | Alto Risco | **Zona Crítica de Cortar** |

> **Insight Operacional:** O quadrante **DTI Crítico (> 45%) + LTV Alto (> 85%)** concentrou as maiores taxas de default do portfólio, sugerindo a criação de um bloqueio automático na política de concessão.

---

## 🔬 Validação Estatística de Hipóteses

Antes da fase de modelagem preditiva, todas as variáveis explicativas foram submetidas a testes de hipóteses formais com nível de significância alpha = 0.05:

* **Variáveis Numéricas Contínuas (`dtir1`, `LTV`, `income`):**
  * **Teste:** Mann-Whitney / Wilcoxon (Não-Paramétrico).
  * **Resultado:** p < 0.001 para todas as variáveis contínuas testadas.
  * **Conclusão:** Rejeita-se a hipótese nula (H0). As distribuições do grupo de inadimplentes são estatisticamente distintas do grupo de adimplentes, confirmando a relevância dessas variáveis para a discriminação de risco.

* **Variáveis Categóricas (`occupancy_type`, `credit_type`, `Region`):**
  * **Teste:** Qui-Quadrado de Independência (Chi2).
  * **Resultado:** p < 0.001 em todas as categorias.
  * **Conclusão:** Rejeita-se a hipótese nula (H0). Existe associação estatisticamente significativa entre essas características cadastrais e o evento de *default*.

---

## 🤖 Modelo Preditivo & Performance

Para atender às exigências de interpretabilidade e conformidade regulatória comuns no setor bancário, foi treinado um modelo de **Regressão Logística (GLM - Binomial Logit)** em **70%** da base de dados, com validação e avaliação no conjunto de teste (**30% de amostra inédita**, ~45 mil contratos).

### Performance do Modelo:
* **Métrica Principal (AUC-ROC):** **`0.784`**
* **Classificação de Mercado:** Alta capacidade de discriminação e ordenação de risco (*Sweet Spot* para modelos operacionais de crédito).

MÉTRICA CHAVE DE RISCO
AUC-ROC no Conjunto de Teste: 0.784 (78.4%)

> **Significado Prático:** Ao selecionar aleatoriamente um contrato inadimplente e um adimplente da base de teste, o modelo atribui uma pontuação de risco maior ao inadimplente em **78,4%** das vezes.

---

## 🛡️ Recomendações Práticas de Concessão

Com base nas análises diagnósticas e na capacidade preditiva do modelo, sugerem-se as seguintes alterações na **Política de Crédito**:

1. **Regra de Bloqueio Automático (Hard Cut):** Rejeitar propostas em que o **LTV seja > 85% combinado com DTI > 45%**, onde a taxa de calote supera o apetite de risco da instituição.
2. **Esteira de Aprovação Automática (*Fast-Track*):** Proponentes com probabilidade predita de default <= 5% (com base no Score gerado pelo modelo) podem ser direcionados para aprovação instantânea, reduzindo custos operacionais de análise humana.
3. **Ajuste Fino de Precificação (*Risk-Based Pricing*):** Aplicar sobretaxa de juros progressiva para operações na faixa intermediária de risco para garantir margem de contribuição adequada frente ao custo de PDD.

---

## 🛠️ Como Executar o Projeto

### Pré-requisitos
Ter o **R (v4.0+)** e o **RStudio** instalados, juntamente com os pacotes:
install.packages(c("dplyr", "ggplot2", "readr", "pROC", "caret", "scales", "tidyr"))

### Passo a Passo:
1. Clone este repositório:
   git clone https://github.com/seu-usuario/credit-risk-analysis-r.git
2. Abra o arquivo de projeto `credit_risk_r.Rproj` no RStudio.
3. Execute o pipeline completo rodando o script mestre `main.R`:
   source("main.R")

---

*Projeto desenvolvido como parte do portfólio de Ciência de Dados e Análise de Risco de Crédito.*

# Ranking Semanal — Specification

**Feature ID prefix:** `RANKW` (ranking) · `NICK` (mudança relacionada de nickname)
**Milestone:** M2 — Competição e contas
**Status:** ✅ Done (2026-06-14)

---

## Problem Statement

O ranking de hoje acumula pontos para sempre — quem jogou cedo e muito fica no topo
indefinidamente, e um jogador novo não tem como alcançar. Isso mata o incentivo de voltar: a
competição parece "decidida". O **ranking semanal** cria uma corrida que **zera toda
segunda-feira**, dando a todos a chance de liderar a cada semana e um motivo concreto para
voltar (somar pontos exige reaparecer ao longo da semana — casa com o teto de energia). É o
mecanismo de retenção semanal do M2.

Além do recorte semanal, esta entrega traz a **fundação extensível** para outros períodos
(mensal, geral) no futuro, corrige um atrito de UX no **nickname** (hoje pedido a cada rodada)
e passa a **identificar melhor** o jogador no ranking (apelido + email mascarado).

## Goals

- [ ] Usuário vê um ranking que considera só as partidas da **semana corrente**
- [ ] Posição definida pela **soma dos pontos** do período (SUM por usuário)
- [ ] A semana **reseta sozinha** na segunda (horário de Brasília), sem job/cron
- [ ] Código **preparado para novos tipos de ranking** (mensal, geral) com mudança mínima
- [ ] Cada linha identifica o jogador por **apelido + email mascarado**
- [ ] Nickname é digitado **uma única vez**; trocar exige ação explícita

## Out of Scope

| Feature | Razão |
|---------|-------|
| Rankings mensal e geral (habilitar) | A **fundação** entra agora; ligar os períodos é trabalho futuro (1 linha de config) |
| Ranking semanal histórico (semanas passadas) | MVP mostra só o período corrente; histórico é M4+ |
| Badges / "Craque da Semana" (premiar o 1º) | Feature própria no roadmap (depende deste ranking) |
| Tie-break sofisticado (quem chegou primeiro à pontuação) | MVP usa ordem estável simples; refinável depois |
| Ranking por categoria/tema | Depende da feature "Categorias por tema" |
| Email completo no ranking | Decidido exibir **mascarado** por privacidade (ranking é público) |

---

## Esquema de Pontuação do Jogo

> Seção informativa — o ranking soma exatamente o `score` definido aqui. Fonte de verdade:
> `app/models/quiz/match_state.rb` (constantes no topo).

Uma partida tem **5 perguntas** (`TOTAL_QUESTIONS = 5`), cada uma com **15 segundos**
(`PER_QUESTION_SECONDS = 15`) e 4 alternativas.

**Pontuação por pergunta:**

| Situação | Pontos |
|----------|--------|
| Resposta **correta** | `BASE_POINTS (60)` + bônus de velocidade |
| Resposta **errada** | 0 |
| **Tempo esgotado** (timeout) | 0 |

**Bônus de velocidade** (só quando acerta): proporcional ao tempo restante, até um teto.

```
seconds_left = max(deadline_at - agora, 0)
bonus        = round( seconds_left / PER_QUESTION_SECONDS * SPEED_BONUS_MAX )   # SPEED_BONUS_MAX = 40
pontos_da_pergunta = BASE_POINTS + bonus                                        # acerto
```

- **Máximo por pergunta:** 60 + 40 = **100** (acerto instantâneo).
- **Máximo por partida:** 5 × 100 = **500**.
- `correct_count` conta os acertos (0–5); `score` é a soma dos pontos (0–500).

**Persistência:** ao terminar a partida, `MatchesController#next_question` grava um
`GameResult` (com `score`, `correct_count`, `questions_count` e `played_at`) **apenas para
usuário logado**. Convidado joga mas não pontua no ranking. → o ranking semanal soma
`GameResult.score` por usuário dentro da janela do período.

---

## User Stories

### P1: Ver o ranking da semana corrente ⭐ MVP

**User Story:** Como jogador, quero ver quem pontuou mais **esta semana**, para sentir uma
competição viva em que ainda dá pra subir.

**Acceptance Criteria:**

1. WHEN o usuário abre `/ranking` THEN o sistema SHALL exibir o ranking do período **Semanal**
   (único período habilitado nesta entrega)
2. WHEN há partidas na semana THEN o sistema SHALL ordenar os usuários pela **soma** de
   `score` (`SUM`) na semana, do maior para o menor, exibindo cada usuário **uma única vez**
3. WHEN a janela da semana é calculada THEN ela SHALL ir de segunda 00h a domingo 23h59 no
   fuso `America/Sao_Paulo`, **sem job** (recorte sob demanda na leitura)
4. WHEN a semana vira (segunda 00h Brasília) THEN o ranking SHALL passar a considerar só a nova
   semana, sem ação manual
5. WHEN a lista é exibida THEN ela SHALL limitar a 50 posições

**Independent Test:** Criar 2 partidas do mesmo usuário na semana (300 + 200) → abrir `/ranking`
→ ver o usuário 1× com total 500; partida da semana passada não aparece.

---

### P1: Fundação extensível para outros períodos ⭐ MVP

**User Story:** Como time de produto, quero poder lançar ranking mensal e geral no futuro sem
reescrever a mecânica, só "ligando" um novo período.

**Acceptance Criteria:**

1. WHEN um novo tipo de ranking por período é necessário (ex.: mensal) THEN adicioná-lo SHALL
   ser uma alteração **localizada** (uma entrada num registro de períodos: chave, rótulo,
   janela de tempo) — sem tocar controller, agregação ou view
2. WHEN mais de um período está habilitado THEN a UI SHALL exibir um **toggle** entre eles
   automaticamente; com um período só, exibe direto sem toggle
3. WHEN o período define janela "tudo" (sem filtro de tempo) THEN a mesma agregação SHALL
   produzir um ranking geral (soma por usuário) — pronto para uso futuro

**Independent Test (futuro):** Descomentar o período `:monthly` no registro → a aba "Mensal"
aparece e ranqueia pela soma do mês, sem outra alteração.

---

### P1: Identificação do jogador (apelido + email mascarado) ⭐ MVP

**User Story:** Como jogador, quero reconhecer quem está no ranking pelo apelido e por uma
pista do email, sem que meu email completo fique exposto publicamente.

**Acceptance Criteria:**

1. WHEN uma linha do ranking é exibida THEN ela SHALL mostrar o **nickname atual** do usuário
   (ou "Anônimo" se ausente) **e** o **email mascarado** (ex.: `d***@gmail.com`)
2. WHEN o email é exibido THEN ele SHALL NUNCA aparecer completo no ranking público
   (mascaramento: 1ª letra do local + `***@` + domínio)
3. WHEN a linha é do próprio usuário logado THEN ela SHALL ser destacada com "(você)"

**Independent Test:** Logar como `daniel@gmail.com`, jogar → ver no ranking
`nickname` + `d***@gmail.com`, nunca o email inteiro.

---

### P2: Estado vazio e acesso do convidado

**Acceptance Criteria:**

1. WHEN o período corrente não tem partidas THEN o sistema SHALL exibir um estado vazio
   ("Nenhum resultado nesta semana ainda"), sem erro
2. WHEN um convidado (sem login) abre `/ranking` THEN ele SHALL ver a lista do período + o CTA
   de login já existente (reaproveitado)

---

## Mudança Relacionada: Nickname digitado uma única vez (`NICK`)

> Atrito observado pelo dono: hoje a home pede o apelido **a cada rodada**. Esta entrega
> corrige isso junto, porque o ranking depende de um nickname estável.

### NICK — Acceptance Criteria

1. WHEN um usuário **logado** está na home THEN o sistema SHALL NOT pedir o apelido — a partida
   usa o `nickname` do cadastro (definido no 1º login, fluxo `nicknames#new`/`create`)
2. WHEN um usuário **logado** quer mudar o apelido THEN ele SHALL ter uma opção explícita
   ("Mudar apelido") que leva ao fluxo de edição do nickname
3. WHEN um **convidado** informa um apelido uma vez THEN o sistema SHALL guardá-lo na sessão e
   **reutilizá-lo** nas próximas partidas, sem pedir de novo
4. WHEN um **convidado** quer trocar o apelido THEN ele SHALL ter uma ação explícita para
   reabrir o campo (não é re-solicitado automaticamente a cada rodada)

**Independent Test:** Logar → iniciar partida sem digitar apelido (usa o do cadastro) → "Mudar
apelido" altera o nickname. Como convidado: digitar apelido na 1ª partida → na 2ª, jogar sem
re-digitar.

---

## Edge Cases

- WHEN dois usuários empatam no total do período THEN a ordem SHALL ser estável (pontos desc e,
  como desempate, `user_id`) — tie-break sofisticado fica deferido
- WHEN o período corrente não tem partidas THEN a aba SHALL mostrar o estado vazio, sem erro
- WHEN se muda o fuso do app para `America/Sao_Paulo` THEN a mecânica de energia (baseada em
  diferença de instantes) SHALL continuar idêntica — fuso não altera intervalos
- WHEN o email tem local de 1 caractere THEN o mascaramento SHALL ainda ocultar (ex.:
  `a***@x.com`), sem vazar o local inteiro
- WHEN um convidado limpa a sessão THEN é aceitável que o apelido seja pedido de novo
  (limitação conhecida, igual ao contador de energia de convidado)

---

## Requirement Traceability

| Requirement ID | Story | Status |
|---------------|-------|--------|
| RANKW-01 | `/ranking` exibe o período Semanal (único habilitado) | Done (T3) |
| RANKW-02 | Ordenar por SUM(score), 1 linha por usuário | Done (T1) |
| RANKW-03 | Janela seg→dom America/Sao_Paulo, sem job | Done (T1) |
| RANKW-04 | Reset automático na virada da semana | Done (T1) |
| RANKW-05 | Limite de 50 posições | Done (T1) |
| RANKW-06 | Fundação extensível (registro de períodos) | Done (T2) |
| RANKW-07 | Toggle automático quando >1 período | Done (T3) |
| RANKW-08 | Linha: posição, nickname, email mascarado, total, nº partidas | Planned (T2/T3) |
| RANKW-09 | Email **mascarado**, nunca completo no público | Done (T2) |
| RANKW-10 | Destaque "(você)" | Done (T3) |
| RANKW-11 | Estado vazio + convidado vê lista + CTA login | Done (T3) |
| RANKW-12 | Fuso não quebra a mecânica de energia | Done (T1) |
| NICK-01 | Logado não digita apelido (usa o do cadastro) | Done (T4) |
| NICK-02 | Opção explícita "Mudar apelido" (logado) | Done (T4) |
| NICK-03 | Convidado guarda apelido na sessão e reutiliza | Done (T4) |
| NICK-04 | Convidado troca apelido por ação explícita | Done (T4) |

---

## Success Criteria

- [ ] A semana soma corretamente os pontos por usuário (1 linha por usuário)
- [ ] O recorte usa segunda 00h de Brasília e reseta sozinho na virada
- [ ] Adicionar um novo período (mensal/geral) é alteração de 1 linha no registro
- [ ] Cada linha mostra nickname + email mascarado; email completo nunca aparece
- [ ] Logado não re-digita apelido; convidado digita uma vez (reusa na sessão)
- [ ] Período vazio mostra estado vazio, sem erro
- [ ] Suíte verde (`bin/rails test:all`)

# Mecânica de Energia — Specification

**Feature ID prefix:** `ENERGY`
**Milestone:** M2 — Competição e contas
**Status:** Specified

---

## Problem Statement

O quiz é jogável sem limite hoje. Para criar retorno diário (retenção) e, sobretudo, para construir o **gancho da assinatura** do M3, introduzimos uma mecânica de energia: cada partida custa 1 energia, com teto de 5 e regeneração ao longo do tempo. O desafio é limitar o jogo o suficiente para gerar hábito e desejo de assinar — sem matar a proposta zero-fricção (convidado ainda joga) nem frustrar o usuário logado com regras opacas. A regra de recarga precisa ser ajustável (vamos calibrar o intervalo na prática).

## Goals

- [ ] Usuário logado tem no máximo 5 energias; cada partida iniciada consome 1
- [ ] Energia gasta regenera sozinha após um intervalo **configurável** (default 2h por energia)
- [ ] Convidado continua jogando, porém com limite menor por sessão e convite a logar
- [ ] Usuário sempre vê quanta energia tem e quando a próxima recarrega
- [ ] A regra (teto, intervalo, limite de convidado) é mudável em **um só lugar** no código

## Out of Scope

| Feature | Razão |
|---------|-------|
| Energia ilimitada para assinantes (implementação) | Depende de assinatura — M3. Aqui só deixamos o gancho `unlimited_energy?` |
| Recarga por assistir anúncio / convidar amigo | M3+ — monetização/growth |
| Notificação push "energia cheia" | Futuro; exige PWA push configurado |
| Reset diário à meia-noite | Descartado em favor do modelo de regeneração por intervalo |
| Compra avulsa de energia | M3 (monetização) |
| Energia por categoria/tema | Depende da feature "Categorias por tema" |

---

## User Stories

### P1: Consumir energia ao iniciar uma partida (logado) ⭐ MVP

**User Story:** Como usuário logado, quero que cada partida que eu inicio consuma 1 energia, para que o jogo tenha um ritmo e eu sinta valor em voltar.

**Why P1:** É o núcleo da mecânica — sem consumo, não há limite nem gancho de monetização.

**Acceptance Criteria:**

1. WHEN um usuário logado com energia ≥ 1 inicia uma partida (`POST /match/start`) THEN o sistema SHALL debitar exatamente 1 energia e iniciar a partida normalmente
2. WHEN a energia é debitada THEN o saldo restante e o horário da próxima recarga SHALL ser persistidos no usuário
3. WHEN o usuário abandona ou reinicia a partida THEN o sistema SHALL NOT devolver a energia já consumida (consumo é no início, definitivo)
4. WHEN o usuário tem `unlimited_energy?` verdadeiro THEN o sistema SHALL NOT debitar energia e SHALL permitir jogar sempre

**Independent Test:** Logar com 5 energias → iniciar partida → ver saldo 4 → reiniciar/abandonar → saldo continua 4.

---

### P1: Bloquear início quando sem energia (logado) ⭐ MVP

**User Story:** Como usuário logado sem energia, quero ser claramente avisado de que preciso esperar (ou — futuramente — assinar), em vez de simplesmente não conseguir jogar.

**Why P1:** Sem o bloqueio, o consumo não tem efeito. É também o ponto onde nasce o desejo de assinar (M3).

**Acceptance Criteria:**

1. WHEN um usuário logado com energia = 0 tenta iniciar uma partida THEN o sistema SHALL NOT iniciar a partida
2. WHEN o início é bloqueado por falta de energia THEN o sistema SHALL exibir tela/estado "Sem energia" com o horário/contagem regressiva da próxima recarga
3. WHEN o usuário está na tela "Sem energia" THEN o sistema SHALL exibir um gancho de upgrade ("Em breve: jogadas ilimitadas para assinantes") — placeholder até o M3
4. WHEN a energia regenera o suficiente (≥ 1) THEN o botão "Jogar" SHALL voltar a funcionar sem recarregar manualmente regras de negócio

**Independent Test:** Zerar a energia do usuário → tentar jogar → ver tela "Sem energia" com contagem → (após intervalo) conseguir jogar de novo.

---

### P1: Regeneração de energia por intervalo configurável ⭐ MVP

**User Story:** Como usuário, quero que minha energia volte sozinha com o tempo, para poder voltar a jogar mais tarde sem fazer nada.

**Why P1:** É o mecanismo de retorno — transforma o limite em hábito ("daqui a 2h jogo de novo").

**Acceptance Criteria:**

1. WHEN se passa 1 intervalo de recarga (default 2h) desde a última atualização THEN o sistema SHALL adicionar 1 energia, até o teto de 5
2. WHEN se passam N intervalos sem o usuário jogar THEN o sistema SHALL adicionar N energias, limitado ao teto (5)
3. WHEN a energia está no teto THEN o sistema SHALL NOT acumular além de 5 nem "guardar" recarga futura
4. WHEN a energia é consumida estando no teto THEN o relógio de recarga SHALL começar a contar a partir desse consumo
5. WHEN o saldo é lido (home, header, tela sem energia) THEN o valor exibido SHALL refletir a energia regenerada até o instante atual (computada sob demanda, sem job)
6. WHEN o operador muda o intervalo/teto no ponto único de configuração THEN o comportamento SHALL mudar sem alterações espalhadas pelo código

**Independent Test:** Gastar 2 energias, recuar o relógio do `recharge_at` em 2 intervalos → ler saldo → ver +2 energias (respeitando o teto).

---

### P1: Convidado com limite menor por sessão + CTA login ⭐ MVP

**User Story:** Como convidado (sem login), quero experimentar o jogo algumas vezes, mas ser convidado a logar para continuar jogando.

**Why P1:** Mantém a entrada zero-fricção e transforma o limite de convidado em alavanca de cadastro (entrada do funil M2/M3).

**Acceptance Criteria:**

1. WHEN um convidado inicia uma partida THEN o sistema SHALL contar a jogada na sessão (sem persistir no BD)
2. WHEN o convidado atinge o limite de convidado (configurável, default 2 jogadas/sessão) THEN o sistema SHALL bloquear novas partidas e exibir "Faça login com Google para jogar mais" com o botão de login
3. WHEN o convidado faz login THEN o sistema SHALL passar a aplicar a regra de energia de usuário logado (5 + regeneração)
4. WHEN o convidado limpa a sessão/cookies THEN é aceitável que o contador reinicie (limitação conhecida, não é objetivo bloquear isso no MVP)

**Independent Test:** Sem login, jogar até o limite de convidado → ver bloqueio com CTA de login → logar → poder jogar dentro da regra de 5 energias.

---

### P2: Indicador de energia visível durante a navegação

**User Story:** Como usuário logado, quero ver minha energia (ex.: "⚡ 3/5") e quando a próxima recarrega, em qualquer tela do jogo.

**Why P2:** Reforça a mecânica e o desejo de voltar, mas o jogo funciona com o aviso só no momento do bloqueio (P1).

**Acceptance Criteria:**

1. WHEN um usuário logado está na home ou no header do quiz THEN o sistema SHALL exibir o saldo atual de energia (ex.: `⚡ 3/5`)
2. WHEN a energia não está cheia THEN o sistema SHALL exibir um indicador de tempo até a próxima recarga
3. WHEN a energia está cheia THEN o sistema SHALL exibir o estado "cheia" sem contagem regressiva

**Independent Test:** Logar → ver `⚡ 5/5` → jogar → ver `⚡ 4/5` com "próxima recarga em ~2h".

---

## Edge Cases

- WHEN o relógio do servidor avança muito (usuário ausente por dias) THEN a energia SHALL ser exatamente o teto (5), nunca mais
- WHEN dois requests de `start` chegam quase simultâneos (duplo clique) THEN o sistema SHALL debitar no máximo a energia disponível (não permitir saldo negativo) — atomicidade no débito
- WHEN `recharge_at`/timestamp está nulo (usuário criado antes da feature) THEN o sistema SHALL tratar como energia cheia na primeira leitura
- WHEN um convidado já no limite faz login com conta sem energia THEN vale a regra do logado (pode cair direto em "Sem energia") — comportamento aceito
- WHEN `unlimited_energy?` é verdadeiro THEN nenhum indicador de recarga é necessário (mostrar "∞")

---

## Requirement Traceability

| Requirement ID | Story | Status |
|---------------|-------|--------|
| ENERGY-01 | P1: Debitar 1 energia ao iniciar partida (logado) | Done (T3: gate em `#start`) |
| ENERGY-02 | P1: Não devolver energia em abandono/reinício | Done (T2: débito definitivo no início) |
| ENERGY-03 | P1: Respeitar `unlimited_energy?` (sem débito) | Done (T2/T3) |
| ENERGY-04 | P1: Bloquear início com energia = 0 | Done (T3) |
| ENERGY-05 | P1: Tela "Sem energia" com próxima recarga + gancho de upgrade | Done (T3) |
| ENERGY-06 | P1: Regenerar 1 energia por intervalo, até o teto | Done (T1) |
| ENERGY-07 | P1: Saldo computado sob demanda (sem job de background) | Done (T1) |
| ENERGY-08 | P1: Configuração única de teto/intervalo/limite de convidado | Done (T1) |
| ENERGY-09 | P1: Convidado — contador por sessão | Done (T3) |
| ENERGY-10 | P1: Convidado — bloqueio no limite + CTA login | Done (T3) |
| ENERGY-11 | P2: Indicador de energia no header/home | Pending |
| ENERGY-12 | P2: Tempo até próxima recarga no indicador | Pending |

---

## Success Criteria

- [ ] Usuário logado nunca inicia mais de 5 partidas sem esperar a regeneração
- [ ] A energia regenera corretamente com o tempo, sem job de background, respeitando o teto
- [ ] Mudar o intervalo de recarga (ex.: 2h → 1h) é uma alteração de uma linha
- [ ] Convidado é bloqueado após o limite de sessão e vê CTA de login
- [ ] Débito de energia é atômico (sem saldo negativo em duplo clique)
- [ ] Nenhum usuário criado antes da feature quebra (timestamp nulo = energia cheia)

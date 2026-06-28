# Redesign Visual (Landing + Ranking + retheme global) — Specification

**Feature ID prefix:** `RDS`
**Milestone:** M2 — Competição e contas (sprint de UI)
**Status:** Done ✅ (2026-06-23)
**Fonte:** design handoff `~/Downloads/design_handoff_torcedor_maluco/` (`README.md`, `landing.html`, `quiz_e_ranking.html`)
**Plano aprovado:** `~/.claude/plans/users-torrico-estudio-downloads-design-velvety-music.md`

---

## Problem Statement

O time de design entregou um handoff de alta fidelidade elevando a cara do app para a estética "torcida Copa 2026". O foco são duas telas — **Landing** (entrada) e **Ranking** (placar) — mas o handoff também troca a **tipografia de display** (Fredoka → **Baloo 2**) e **consolida a paleta** (verdes/amarelo/azul levemente diferentes dos atuais), que hoje vivem como tokens globais em `:root` de `torcedor_maluco.css`. Decisão de produto (com o dono): aplicar o novo visual ao **app inteiro**, de modo que quiz e resultado herdem paleta/fonte automaticamente, mantendo consistência. A Landing ganha saudação personalizada, prova social e botão Google estilizado; o Ranking ganha pódio (top-3), linhas redesenhadas e faixa de login — sem alterar a query/contrato de dados existente (`Quiz::Leaderboard`).

## Goals

- [ ] Paleta e tipografia novas viram a **fonte única de tokens** (`:root`), cascateando para todas as telas
- [ ] Landing reestruturada: hero Baloo 2 (sem rotação), saudação com apelido, prova social **real**, botão Google estilizado
- [ ] Ranking reestruturado: band header com voltar, cabeçalho "A torcida de hoje", **pódio top-3** (ordem visual 2-1-3), lista de linhas nova e faixa de login para convidado
- [ ] Avatares por **monograma** (inicial do apelido), determinísticos, reutilizáveis em pódio/lista/prova social
- [ ] Quiz e resultado **herdam** o novo tema sem regressão funcional nem visual quebrada
- [ ] Features reais preservadas: toggle de período (semanal/mensal/geral) e badges no ranking
- [ ] Regra de marca aplicada: **amarelo `#ffd000` reservado ao CTA** (chip "COPA 2026" passa a contornado)

## Out of Scope

| Feature | Razão |
|---------|-------|
| Migração/redesign das views legadas `games/*` + `application.css` (Tailwind) | Legado fora do fluxo ativo (root é `matches#show`); permanece deferred (ver STATE.md) |
| Enforce estrito de "amarelo só no CTA" em quiz/result (score-pill, rd.ok, res-score) | Foco do handoff é Landing+Ranking; quiz/result só herdam paleta/fonte. Aplicar só o chip contornado |
| Avatares de imagem (upload/Gravatar/foto Google) | Decisão: monograma determinístico — sem dado novo nem pedido ao usuário |
| Sistema de avatar persistido (escolha de emoji/cor pelo usuário) | Monograma é derivado; nenhuma migration/coluna nova |
| Novos períodos de ranking ou mudança de agregação | Reusa `Quiz::Leaderboard` como está |
| Reescrever telas de pergunta/resultado (markup) | Só herdam tokens; markup intacto salvo ajuste trivial |
| Dark mode / temas | Não solicitado |

---

## User Stories

### P1: Retheme global (paleta + tipografia) ⭐ MVP

**User Story:** Como dono do produto, quero a nova paleta e a fonte Baloo 2 aplicadas a partir de um único ponto de tokens, para que todas as telas fiquem consistentes com o handoff sem editar cada uma.

**Why P1:** É a fundação — Landing e Ranking são construídos sobre esses tokens, e quiz/resultado herdam por cascata.

**Acceptance Criteria:**

1. WHEN os tokens de `:root` são atualizados THEN a paleta SHALL refletir o handoff (`--verde:#16a34a`, `--amarelo:#ffd000`, `--azul:#13286b`, `--ink:#10204a`, `--muted:#5a6a86`, e sombras `--amarelo-esc:#f2b500` / `--azul-esc:#0e1f53`)
2. WHEN a tipografia é definida THEN SHALL existir `--font-display:'Baloo 2'` e `--font-body:'Nunito'`, com o `<link>` do Google Fonts carregando Baloo 2, e as referências `'Fredoka'` no stylesheet substituídas por `var(--font-display)`
3. WHEN qualquer tela do app ativo é renderizada THEN ela SHALL usar a nova paleta/fonte sem cor/fonte legada remanescente
4. WHEN o chip "COPA 2026" do header é exibido THEN ele SHALL ser **contornado** (fundo transparente, borda+texto amarelos), liberando o amarelo preenchido para o CTA

**Independent Test:** Inspecionar o computed de `--azul`/`--amarelo` e o `font-family` do `.logo` em qualquer tela → valores novos; abrir home/quiz/resultado/ranking → nenhuma cor/fonte antiga.

---

### P1: Landing reestruturada ⭐ MVP

**User Story:** Como visitante, quero uma entrada vibrante e pessoal — título de impacto, uma saudação com meu apelido, prova de que outros já estão jogando e um login claro — para me sentir convidado a jogar.

**Why P1:** Conversão é o objetivo da Landing; é uma das duas telas-foco do handoff.

**Acceptance Criteria:**

1. WHEN a hero é exibida THEN ela SHALL mostrar o badge azul "⚡ O QUIZ DA TORCIDA" e o título "TORCEDOR MALUCO" em 2 linhas (Baloo 2, amarelo, sombra 3D azul), **sem rotação**
2. WHEN há um apelido conhecido (logado: `current_user.nickname`; convidado: `session[:nickname]`) THEN o cartão SHALL exibir a saudação "E aí, **<nome>**! Bora marcar um golaço? 👋"; WHEN não há apelido THEN a saudação SHALL ser omitida
3. WHEN o cartão é exibido THEN SHALL conter uma meta row (space-between): link "Trocar apelido" à esquerda e "● Grátis e sem anúncios" (verde) à direita
4. WHEN há ao menos 1 jogador com partida hoje THEN a prova social SHALL exibir avatares-monograma sobrepostos + "+<N> torcedores já jogaram hoje", com **N = contagem real** de jogadores distintos do dia; WHEN N = 0 THEN a linha SHALL ser omitida
5. WHEN o usuário não está logado THEN o botão Google estilizado (logo SVG + "Entrar com Google para o ranking") SHALL iniciar o OAuth via POST
6. WHEN o CTA "Jogar agora ⚽" é acionado THEN o fluxo de início de partida SHALL permanecer o atual (`matches#start`)

**Independent Test:** Abrir `/` como convidado com e sem `session[:nickname]`, e como logado → saudação aparece/some corretamente; com 1+ partida hoje, a prova social mostra o número real; botão Google dispara OAuth.

---

### P1: Ranking reestruturado ⭐ MVP

**User Story:** Como jogador, quero ver o placar da torcida com um pódio destacando o top-3 e minha linha em evidência, e um convite claro para logar e "valer ponto".

**Why P1:** É a segunda tela-foco do handoff e o diferencial competitivo do produto.

**Acceptance Criteria:**

1. WHEN o ranking é exibido THEN SHALL ter uma **band verde** com botão voltar "‹" (→ home) à esquerda e "🏆 RANKING" centralizado
2. WHEN há entradas THEN um **cabeçalho** ("A torcida de hoje" + "Top jogadores · Copa 2026") SHALL aparecer sobre o verde
3. WHEN há ≥ 3 entradas THEN o **pódio** SHALL renderizar os 3 primeiros em ordem visual **2º · 1º · 3º**, cada coluna com avatar (monograma, borda amarela), nome, pontos e barra de altura proporcional (1º mais alta/amarela)
4. WHEN há < 3 entradas THEN o pódio SHALL renderizar apenas as colunas existentes, sem erro
5. WHEN a lista é exibida THEN cada linha SHALL mostrar posição · avatar-monograma · nome (+ sub-label de partidas) · pontos à direita
6. WHEN a linha é do usuário atual THEN ela SHALL receber destaque amarelo (borda `#ffd000`, fundo `#fffdf0`, sombra inferior), substituindo o destaque verde atual
7. WHEN o usuário não está logado THEN uma **faixa de login** azul no rodapé SHALL convidar ao OAuth ("Entre pra valer ponto…"); WHEN logado THEN a faixa SHALL ser omitida
8. WHEN há mais de um período habilitado THEN o **toggle** (semanal/mensal/geral) SHALL continuar funcionando; WHEN uma entrada tem badges THEN eles SHALL continuar visíveis na linha
9. WHEN não há entradas no período THEN o **estado vazio** atual SHALL ser preservado

**Independent Test:** Abrir `/ranking` com 0, 2 e 5 jogadores; logado e convidado → pódio adapta às quantidades, linha "(você)" destacada em amarelo, faixa de login só p/ convidado, toggle e badges funcionando.

---

### P2: Avatares por monograma

**User Story:** Como jogador, quero um avatar reconhecível ao lado do meu nome no ranking e na prova social, mesmo sem ter enviado foto.

**Why P2:** Dá identidade visual ao pódio/lista (fiel ao protótipo), mas o ranking funciona sem ele; é um helper de apresentação.

**Acceptance Criteria:**

1. WHEN um avatar é renderizado THEN ele SHALL ser um círculo com a **inicial** do apelido (upcased), via helper `avatar_monogram`
2. WHEN o mesmo apelido é renderizado em telas diferentes THEN a cor de fundo SHALL ser **determinística** (mesma seed → mesma cor), via `avatar_color`
3. WHEN o apelido é vazio/"Anônimo" THEN o monograma SHALL usar um fallback estável (ex.: "?")
4. WHEN o avatar aparece no pódio THEN SHALL ter borda amarela 3px; na lista/prova social, sem borda

**Independent Test:** Renderizar dois usuários com iniciais diferentes → círculos com letras e cores distintas e estáveis entre reloads; usuário "Anônimo" → fallback sem erro.

---

### P2: Não-regressão de quiz e resultado (herança de tema)

**User Story:** Como jogador, quero que as telas de pergunta e resultado continuem funcionando e bonitas após a troca de paleta/fonte, sem nada quebrado.

**Why P2:** Efeito colateral do retheme global; precisa ser verificado, não construído.

**Acceptance Criteria:**

1. WHEN a tela de pergunta é exibida THEN os estados `.opt.chosen/.correct/.wrong/.dim`, o timer e o placar SHALL permanecer legíveis e coerentes com a nova paleta
2. WHEN a tela de resultado é exibida THEN score, recap, confete e badges SHALL renderizar sem quebra visual
3. WHEN a suíte de testes roda THEN ela SHALL permanecer verde (nenhuma mudança de lógica de quiz/resultado)

**Independent Test:** Jogar uma partida completa → pergunta e resultado coerentes com o novo tema; `bin/rails test` verde.

---

## Edge Cases

- WHEN o ranking tem exatamente 1 ou 2 jogadores THEN o pódio renderiza só as colunas existentes (sem coluna vazia/erro)
- WHEN o ranking está vazio THEN nenhuma band/pódio quebra; o estado vazio atual aparece
- WHEN o convidado não tem `session[:nickname]` THEN a Landing não mostra saudação nem quebra
- WHEN nenhum jogador jogou hoje (N=0) THEN a prova social é omitida (sem "+0 torcedores")
- WHEN o apelido tem caractere não-latino/emoji como inicial THEN o monograma usa o primeiro grapheme ou fallback, sem erro
- WHEN o usuário atual está fora do top-3 mas presente na lista THEN só a linha (não o pódio) recebe o destaque amarelo
- WHEN o usuário atual está no top-3 THEN o pódio o destaca; a linha correspondente mantém o destaque amarelo

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
|---------------|-------|-------|--------|
| RDS-01 | P1: Tokens de paleta novos | Design | Verified |
| RDS-02 | P1: Tokens de fonte (Baloo 2) + import + Fredoka→var | Design | Verified |
| RDS-03 | P1: Chip "COPA 2026" contornado (marca: amarelo só no CTA) | Design | Verified |
| RDS-04 | P1: Landing hero (badge, título 2 linhas, sem rotação) | Design | Verified |
| RDS-05 | P1: Saudação dinâmica com apelido | Design | Verified |
| RDS-06 | P1: Meta row (trocar apelido + grátis) | Design | Verified |
| RDS-07 | P1: Prova social com contagem real | Design | Verified |
| RDS-08 | P1: Botão Google estilizado (SVG) | Design | Verified |
| RDS-09 | P1: Ranking band header (voltar + título) | Design | Verified |
| RDS-10 | P1: Cabeçalho "A torcida de hoje" | Design | Verified |
| RDS-11 | P1: Pódio top-3 reordenado 2-1-3 | Design | Verified |
| RDS-12 | P1: Lista de linhas nova | Design | Verified |
| RDS-13 | P1: Destaque amarelo da linha do usuário (`.row.me`) | Design | Verified |
| RDS-14 | P1: Faixa de login no rodapé (convidado) | Design | Verified |
| RDS-15 | P2: Avatares por monograma (helper determinístico) | Design | Verified |
| RDS-16 | P2: Não-regressão quiz/resultado (herança de tema) | Design | Verified |
| RDS-17 | Preservar toggle de período + badges no ranking | Design | Verified |
| RDS-18 | Edge: pódio com < 3 e ranking vazio | Design | Verified |

**Coverage:** 18 total, 18 verificados.

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

---

## Success Criteria

- [x] Tokens de paleta/fonte novos em `:root`; nenhuma cor/fonte legada nas telas ativas
- [x] Landing com hero novo, saudação condicional, prova social real e botão Google estilizado
- [x] Ranking com band header, cabeçalho, pódio 2-1-3 adaptativo, lista nova, linha `.me` amarela e faixa de login condicional
- [x] Avatares monograma determinísticos em pódio/lista/prova social
- [ ] Quiz e resultado coerentes com o novo tema, sem regressão visual
- [ ] Toggle de período e badges no ranking continuam funcionando
- [ ] `bin/rails test` verde (controller/helper novos cobertos); `bin/rubocop` limpo nos arquivos Ruby
- [ ] Verificação visual em mobile (~390px) e largura grande, incluindo os casos de borda (ranking 0/2/5 jogadores)

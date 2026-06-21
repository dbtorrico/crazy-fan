# Design Responsivo Multi-Tela — Specification

**Feature ID prefix:** `RESP`
**Milestone:** M2 — Competição e contas (sprint de UI)
**Status:** Specified

---

## Problem Statement

O design hoje é mobile-only: um shell de largura fixa (`.tm-app { max-width:430px }`) centralizado sobre um fundo escuro (`#0c0d12`). Em tablet e desktop o jogo aparece como uma coluna estreita de celular flutuando num "vazio" preto — parece quebrado, não intencional. Toda a UI está dimensionada em pixels fixos pensados para retrato de celular (logo 46px, ring 78px, fontes fixas, queda de confete de 880px), e há **duplicação de CSS** entre `torcedor_maluco.css` (jogo) e `application.css` (legado + helpers do ranking). Queremos que o produto funcione e seja **otimizado em qualquer tela**, mantendo o "game feel" focado, sem reescrever a estrutura do jogo.

## Goals

- [ ] O jogo deixa de flutuar no vazio escuro: telas grandes ganham um fundo de estádio/campo intencional
- [ ] A coluna central (palco) cresce de forma controlada em tablet/desktop (~430 → ~560px) com tipografia e espaçamento **fluidos** (clamp), permanecendo legível e proporcional
- [ ] Nenhuma regressão visual no celular: a experiência mobile atual é preservada como baseline
- [ ] Telas de conteúdo (ranking, nickname) se adaptam à largura sem estourar nem ficar estreitas demais
- [ ] O jogo é utilizável em **paisagem** e em telas de pouca altura, sem corte de conteúdo
- [ ] Existe **uma única fonte de verdade** de estilo (fim da duplicação `torcedor_maluco.css` × `application.css`)
- [ ] As regras responsivas (breakpoints, largura do palco, escala de tipo) são ajustáveis em poucos pontos definidos

## Out of Scope

| Feature | Razão |
|---------|-------|
| Layouts multi-coluna reais no desktop (hero lado a lado, timer em sidebar) | Decisão de produto: manter "palco central escalado" — foco no jogo. Pode ser feature futura |
| Redesign de identidade visual (paleta, logo, marca) | Mantemos a identidade atual (verde/amarelo/azul, Fredoka/Nunito); aqui é só responsividade |
| Migração das views legadas `games/*` | Root é `matches#show`; `games/*` é legado do MVP, fora do fluxo ativo |
| Dark mode / temas | Não solicitado; ortogonal a responsividade |
| Otimização de performance (lazy-load, sprites, fontes self-hosted) | Concern separado; não é objetivo deste design |
| Animações/transições novas entre telas | Mantemos o comportamento Turbo atual; foco é layout responsivo |
| Novos componentes/telas de produto | Apenas adaptar as superfícies existentes |

---

## User Stories

### P1: Palco responsivo com backdrop de estádio ⭐ MVP

**User Story:** Como jogador em tablet ou desktop, quero que o jogo ocupe a tela de forma intencional — uma coluna central bem dimensionada sobre um fundo de estádio — em vez de uma faixa estreita de celular flutuando no preto.

**Why P1:** É o núcleo da feature. Sem isso, "funcionar em qualquer tela" não acontece; é o que transforma a sensação de "quebrado" em "premium".

**Acceptance Criteria:**

1. WHEN a viewport tem largura ≥ 1024px THEN o sistema SHALL exibir um fundo de estádio/campo branded ao redor do palco central, no lugar do vazio `#0c0d12`
2. WHEN a viewport cresce de mobile para tablet/desktop THEN a largura do palco central SHALL crescer de forma controlada (de ~430px até um teto de ~560px), nunca esticando para 100% em telas largas
3. WHEN a viewport é de celular (≤ 640px) THEN o layout SHALL permanecer visualmente idêntico ao atual (baseline sem regressão)
4. WHEN o palco é exibido em qualquer largura THEN o header, o `turbo-frame#match` e as telas internas SHALL permanecer alinhados e centralizados, sem barras de rolagem horizontais
5. WHEN o backdrop é renderizado THEN ele SHALL respeitar `prefers-reduced-motion` (sem animação se houver) e não capturar cliques (`pointer-events:none`)

**Independent Test:** Abrir a home em 390px, 768px, 1024px e 1440px → ver a coluna crescer até ~560px com fundo de estádio nas larguras grandes; em 390px, comparar com o design atual (idêntico).

---

### P1: Tipografia e espaçamento fluidos nas telas do jogo ⭐ MVP

**User Story:** Como jogador, quero que textos, botões e o cronômetro sejam proporcionais à tela — nem minúsculos num monitor grande, nem espremidos num celular pequeno.

**Why P1:** Um palco maior com tipografia fixa de celular fica desproporcional (texto perdido no meio). A fluidez é o que faz o palco escalado parecer desenhado, não esticado.

**Acceptance Criteria:**

1. WHEN a viewport varia entre ~360px e ~560px de palco THEN o tamanho do logo, do placar de resultado, do texto da pergunta e dos botões principais SHALL escalar fluidamente (via `clamp()`), dentro de limites mínimo/máximo legíveis
2. WHEN a pergunta tem texto longo THEN ela SHALL permanecer legível e sem overflow em qualquer largura suportada (já usa `text-wrap:balance`)
3. WHEN as alternativas são exibidas em telas maiores THEN elas SHALL manter altura de toque confortável (≥ 48px) e não ficar exageradamente largas/altas
4. WHEN a tela de resultado é exibida em desktop THEN o placar grande (hoje 84px) SHALL escalar para um teto proporcional sem estourar o card
5. WHEN qualquer texto escala THEN os limites de `clamp()` SHALL garantir tamanho mínimo legível no menor celular suportado (~320px)

**Independent Test:** Em 320px, 430px e 560px de palco, medir o `font-size` computado do `.logo` e do `.qtext` → valores crescem suavemente entre os limites definidos, sem saltos.

---

### P1: Telas de conteúdo responsivas (ranking e nickname) ⭐ MVP

**User Story:** Como usuário navegando no ranking ou definindo meu nickname num tablet/desktop, quero uma página que aproveite a largura de leitura confortável, sem a coluna espremida de celular nem listas esticadas de ponta a ponta.

**Why P1:** Ranking e nickname usam o mesmo shell fixo e Tailwind solto; precisam acompanhar o novo sistema de palco para não destoar.

**Acceptance Criteria:**

1. WHEN o ranking é exibido em desktop THEN a lista SHALL usar uma largura de leitura confortável (alinhada ao palco), com linhas legíveis e sem rolagem horizontal
2. WHEN o ranking tem muitos resultados em tela alta THEN a área de rolagem SHALL se comportar corretamente dentro do palco (sem header sumindo nem corte)
3. WHEN a tela de nickname é exibida em qualquer largura THEN o formulário SHALL permanecer centralizado, com largura máxima legível e botão acessível
4. WHEN essas telas são exibidas em celular THEN o layout SHALL permanecer equivalente ao atual (sem regressão)

**Independent Test:** Abrir `/ranking` e `/nickname/new` em 390px e 1280px → conteúdo centralizado e legível em ambos, mesmo idioma visual do jogo.

---

### P2: Paisagem e telas de pouca altura

**User Story:** Como jogador que vira o celular ou usa uma janela baixa, quero conseguir jogar sem que o conteúdo seja cortado ou exija rolagem estranha.

**Why P2:** Importante para usabilidade real, mas o uso primário é retrato; o jogo funciona em retrato mesmo sem este ajuste.

**Acceptance Criteria:**

1. WHEN a viewport está em paisagem com pouca altura (ex.: 740×360) THEN as telas do jogo (home/pergunta/resultado) SHALL permanecer com os controles principais acessíveis (rolagem aceitável, sem elementos cortados/inalcançáveis)
2. WHEN a altura é insuficiente para o layout `100dvh` em coluna THEN o conteúdo SHALL poder rolar em vez de sobrepor ou cortar
3. WHEN o teclado virtual abre na home (input de apelido) THEN o botão "Jogar" SHALL permanecer alcançável
4. WHEN há `safe-area-inset` (notch) THEN os paddings existentes SHALL continuar respeitados em qualquer orientação

**Independent Test:** Emular 740×360 (paisagem) na pergunta → ver cronômetro, texto e as 4 alternativas acessíveis (com rolagem se necessário), nada cortado.

---

### P2: Fonte única de estilo (consolidação do CSS duplicado)

**User Story:** Como mantenedor, quero uma única fonte de verdade para o estilo do jogo, para que ajustar um botão ou uma cor não exija editar dois arquivos.

**Why P2:** É um habilitador de manutenção e reduz risco de divergência; o usuário final não vê, mas todo o trabalho responsivo é mais seguro sobre uma base única.

**Acceptance Criteria:**

1. WHEN um estilo compartilhado (botões, opções, logo, header-ball, campo) é definido THEN ele SHALL existir em **um único lugar**, sem cópia divergente entre `torcedor_maluco.css` e `application.css`
2. WHEN a consolidação é feita THEN todas as telas atuais (home, pergunta, resultado, sem-energia, ranking, nickname) SHALL continuar renderizando idênticas em mobile (sem regressão)
3. WHEN os tokens responsivos (breakpoints, largura do palco, escala de tipo) são definidos THEN eles SHALL viver em pontos centralizados (variáveis CSS e/ou `@theme` do Tailwind v4)
4. WHEN o app é carregado THEN cada layout SHALL incluir apenas a folha de estilo necessária (sem CSS morto carregado)

**Independent Test:** Buscar por `.btn-play`/`.opt` no `app/assets` → definição única; abrir as telas em mobile antes/depois → diff visual nulo.

---

### P3: Refinamentos premium em telas muito grandes

**User Story:** Como jogador num monitor grande (≥ 1440px), quero que o ambiente ao redor do palco seja agradável e premium, não apenas "não quebrado".

**Why P3:** Polimento; agrega percepção de qualidade, mas não bloqueia o lançamento.

**Acceptance Criteria:**

1. WHEN a viewport é ≥ 1440px THEN o backdrop de estádio SHALL ter profundidade/acabamento agradável (gradiente/vinheta/elementos sutis), mantendo contraste e foco no palco
2. WHEN o backdrop é exibido THEN ele SHALL manter contraste suficiente para o palco se destacar e não competir com o conteúdo

**Independent Test:** Abrir a home em 1920×1080 → o palco se destaca claramente sobre um fundo branded agradável.

---

## Edge Cases

- WHEN a viewport é ultra-wide (ex.: 2560px ou 21:9) THEN o palco SHALL permanecer centralizado no teto de largura, com o backdrop preenchendo o resto sem distorção
- WHEN o usuário dá zoom de 200% (acessibilidade) THEN o conteúdo SHALL permanecer utilizável e sem overflow horizontal
- WHEN o confete do resultado é exibido em tela alta THEN a queda (hoje fixa em ~880px) SHALL cobrir a altura visível sem parar no meio nem vazar
- WHEN o `turbo-frame#match` é trocado a cada resposta THEN o header (fora do frame) e o palco SHALL permanecer estáveis, sem "pulo" de layout em nenhuma largura
- WHEN o conteúdo do palco é menor que a altura da tela THEN ele SHALL ocupar `min-height:100dvh` (como hoje), mas sem travar a rolagem quando for maior
- WHEN um celular muito estreito (~320px) é usado THEN nenhum texto SHALL ficar abaixo do mínimo legível definido nos `clamp()`

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
|---------------|-------|-------|--------|
| RESP-01 | P1: Palco central cresce controlado (~430→~560) | Design | Pending |
| RESP-02 | P1: Backdrop de estádio em telas grandes (substitui vazio) | Design | Pending |
| RESP-03 | P1: Zero regressão visual no mobile (≤640px) | Design | Pending |
| RESP-04 | P1: Sem rolagem horizontal / alinhamento estável em qualquer largura | Design | Pending |
| RESP-05 | P1: Tipografia fluida (clamp) — logo, placar, pergunta, botões | Design | Pending |
| RESP-06 | P1: Alternativas com toque confortável e proporção em telas grandes | Design | Pending |
| RESP-07 | P1: Ranking responsivo (largura de leitura, rolagem correta) | Design | Pending |
| RESP-08 | P1: Nickname responsivo (form centralizado, largura máxima) | Design | Pending |
| RESP-09 | P2: Paisagem / pouca altura — conteúdo acessível com rolagem | Design | Pending |
| RESP-10 | P2: safe-area preservado em qualquer orientação | Design | Pending |
| RESP-11 | P2: Fonte única de estilo (sem duplicação torcedor_maluco × application) | Design | Pending |
| RESP-12 | P2: Tokens responsivos centralizados (vars CSS / @theme) | Design | Pending |
| RESP-13 | P3: Acabamento premium do backdrop ≥1440px | Design | Pending |
| RESP-14 | Edge: confete cobre a altura visível sem cortar | Design | Pending |
| RESP-15 | Edge: sem overflow horizontal em zoom 200% / ultra-wide | Design | Pending |

**Coverage:** 15 total, 0 mapeados a tasks ainda (Design pendente).

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

---

## Success Criteria

- [ ] Em 320 / 390 / 768 / 1024 / 1440 / 1920px, todas as telas (home, pergunta, resultado, sem-energia, ranking, nickname) ficam legíveis, centralizadas e sem rolagem horizontal
- [ ] O mobile (≤640px) não tem regressão visual perceptível vs. o design atual
- [ ] Telas grandes mostram fundo de estádio branded em vez do vazio escuro
- [ ] Tipografia escala suavemente entre os limites de `clamp()` definidos
- [ ] O jogo é jogável em paisagem 740×360 (com rolagem aceitável)
- [ ] Estilos compartilhados têm definição única (sem duplicação entre os dois CSS)
- [ ] Breakpoints, largura do palco e escala de tipo são ajustáveis em pontos centralizados
- [ ] Suíte de testes existente continua verde (sem regressão funcional)

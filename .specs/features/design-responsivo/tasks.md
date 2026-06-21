# Design Responsivo Multi-Tela — Tasks

**Design:** `.specs/features/design-responsivo/design.md`
**Spec:** `.specs/features/design-responsivo/spec.md`
**Testing:** `.specs/codebase/TESTING.md` (views estáticas → none; tela no navegador → system)
**Status:** Ready for execution
**Baseline:** suíte atual deve permanecer verde (feature de apresentação, sem mudança funcional)

---

## Execution Plan

### Phase 1: Fundação (Sequential)

```
T1 (tokens + palco responsivo + backdrop)  ← tudo depende disto
```

### Phase 2: Camadas paralelas (após T1)

```
T1 ──→ T2 [P] (componentes fluidos: jogo)
T1 ──→ T3 [P] (confete + paisagem/baixa altura)
T1 ──→ T4 [P] (ranking responsivo)
T1 ──→ T5 [P] (nickname responsivo)
T1 ──→ T7 [P] (premium ≥1440 — P3, opcional)
```

### Phase 3: Consolidação + Verificação (Sequential)

```
T4, T5 → T6 (fonte única / congelar legado)
T2..T7 → T8 (matriz visual + suíte verde)
```

---

## Task Breakdown

### T1: Tokens + palco responsivo + backdrop de estádio

**What:** Criar a camada de tokens no `:root` (largura do palco, escala de tipo fluida, espaçamento), tornar `.tm-app` um container responsivo (`max-width` por breakpoint, `container-type:inline-size`, rolagem relaxada) e substituir o vazio escuro do `body` por um backdrop de estádio em CSS puro. Esta é a fundação de tudo.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (`:root`, `html,body`, `.tm-app`, novos `@media`)
**Depends on:** None
**Reuses:** `:root` existente; padrão visual `.field`; `allow_browser :modern` (habilita `cqi`/`dvh`)
**Requirement:** RESP-01, RESP-02, RESP-03, RESP-04, RESP-12

**Tools:** MCP: Claude_Preview/Chrome (verificação visual) · Skill: NONE

**Done when:**
- [ ] `:root` ganha tokens: `--stage-max` + `--fs-logo`, `--fs-qtext`, `--fs-score`, `--fs-btn`, `--fs-opt`, `--ring-size`, `--pad-screen` (valores iniciais da tabela do design.md)
- [ ] `.tm-app`: `max-width: var(--stage-max)`, `width:100%`, `container-type:inline-size`, `margin-inline:auto`; `overflow:hidden` removido/relaxado para permitir rolagem
- [ ] Breakpoints centralizados: `--stage-max` = 430 (base) / 480 (≥700px) / 560 (≥1024px)
- [ ] `body`/pseudo-elementos: backdrop de estádio (gradiente verde + listras `.field` + vinheta), `pointer-events:none`, estático
- [ ] Em ≤640px o layout é **idêntico ao atual** (palco 430px, backdrop oculto sob o palco)
- [ ] Em ≥1024px o backdrop aparece ao redor do palco (não mais `#0c0d12`)
- [ ] Sem rolagem horizontal em 320/390/768/1024/1440/1920
- [ ] `bin/rails test` permanece verde
- [ ] Verificação visual nos 6 breakpoints (home)

**Tests:** none (CSS) · **Gate:** quick (`bin/rails test`) + visual
**Commit:** `feat(design): tokens responsivos, palco fluido e backdrop de estádio`

---

### T2: Componentes do jogo fluidos (logo, pergunta, placar, timer, botões, opções) [P]

**What:** Trocar os tamanhos fixos dos componentes das telas do jogo pelos tokens de `clamp()`/`cqi` definidos em T1, mantendo mínimos legíveis e tetos que não estouram os cards. Markup praticamente intacto.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (`.logo .l1/.l2`, `.qtext`, `.res-score`, `.res-pts`, `.ring`/`.num`, `.btn-play`, `.btn-share`, `.opt`)
**Depends on:** T1
**Reuses:** todas as classes/estados existentes (`.chosen/.correct/.wrong/.dim`) — só o dimensionamento muda
**Requirement:** RESP-05, RESP-06

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] `.logo`, `.qtext`, `.res-score`, `.btn-play`, `.opt`, `.ring` consomem os tokens fluidos (sem `font-size` fixo)
- [ ] `.opt` mantém `min-height` ≥ 48px em qualquer largura (toque confortável)
- [ ] Placar do resultado escala até o teto sem estourar o `.result-card`
- [ ] No menor celular (~320px) nenhum texto cai abaixo do mínimo legível dos `clamp()`
- [ ] Mobile (≤640px) sem regressão perceptível vs. atual
- [ ] `bin/rails test` verde
- [ ] Verificação visual de pergunta + resultado em 320/430/560/1024

**Tests:** none (CSS) · **Gate:** quick + visual
**Commit:** `feat(design): tipografia e componentes fluidos nas telas do jogo`

---

### T3: Confete responsivo + paisagem / pouca altura [P]

**What:** Fazer o confete cobrir a altura visível em qualquer tela e garantir que o jogo seja utilizável em paisagem/altura baixa (rolagem em vez de corte), preservando `safe-area`.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (`@keyframes fall`, regras de rolagem, `@media (max-height:480px)` e/ou `@media (orientation:landscape)`)
**Depends on:** T1
**Reuses:** `prefers-reduced-motion` já existente; paddings `safe-area-inset` existentes
**Requirement:** RESP-09, RESP-10, RESP-14, RESP-15

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] `@keyframes fall`: queda baseada em viewport (`105dvh`/`100vh`) — cobre telas altas sem parar no meio
- [ ] Conteúdo que excede a altura **rola** (sem `overflow:hidden` travando), sem elementos cortados/inalcançáveis
- [ ] `@media` de pouca altura reduz paddings/min-heights da home/resultado para caber em paisagem (ex.: 740×360)
- [ ] Botão "Jogar" alcançável com teclado virtual aberto na home
- [ ] `safe-area-inset` continua respeitado em retrato e paisagem
- [ ] Sem overflow horizontal em zoom 200%
- [ ] `bin/rails test` verde
- [ ] Verificação visual em 740×360 (pergunta) e zoom 200% (home)

**Tests:** none (CSS) · **Gate:** quick + visual
**Commit:** `feat(design): confete responsivo e suporte a paisagem/altura baixa`

---

### T4: Ranking responsivo (migrar para classes de componente) [P]

**What:** Reescrever `ranking/index` substituindo os utilitários Tailwind **mortos** (não carregados no `layout matches`) por classes de componente responsivas em `torcedor_maluco.css`, com largura de leitura confortável e rolagem interna correta em telas altas.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (novas `.rank-*`)
- `app/views/ranking/index.html.erb` (reescrever markup)
**Depends on:** T1
**Reuses:** `.hdr`, tokens, paleta; estrutura de dados/ERB existente (não muda controller)
**Requirement:** RESP-07

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] Classes `.rank-wrap` (área rolável no palco), `.rank-cta` (login convidado), `.rank-row` + `.is-me`, `.rank-medal`, `.rank-name`, `.rank-score`, estado vazio
- [ ] `ranking/index.html.erb` usa as novas classes (zero utilitário Tailwind remanescente)
- [ ] Lista legível e centralizada em 390px e 1280px, sem rolagem horizontal
- [ ] Rolagem interna correta com muitos resultados em tela alta (header não some)
- [ ] Destaque do "(você)" preservado
- [ ] `bin/rails test` verde
- [ ] Verificação visual em 390/1280

**Tests:** none (view) · **Gate:** quick + visual
**Commit:** `feat(design): ranking responsivo em classes de componente`

---

### T5: Nickname responsivo (migrar para classes de componente) [P]

**What:** Reescrever `nickname/new` substituindo os utilitários Tailwind mortos por classes de componente, com formulário centralizado e largura máxima legível em qualquer tela.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (novas `.form-*`)
- `app/views/nicknames/new.html.erb` (reescrever markup)
**Depends on:** T1
**Reuses:** `.nick` (input), `.btn`, referência visual `.home-card`
**Requirement:** RESP-08

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] Classes `.form-card`, `.form-title`, `.form-hint`, `.form-error` (reaproveitando `.nick`/`.btn`)
- [ ] `nickname/new.html.erb` usa as novas classes (zero utilitário Tailwind remanescente)
- [ ] Form centralizado, largura máxima legível, botão acessível em 390px e 1280px
- [ ] Mensagem de erro de validação preservada
- [ ] `bin/rails test` verde
- [ ] Verificação visual em 390/1280

**Tests:** none (view) · **Gate:** quick + visual
**Commit:** `feat(design): tela de nickname responsiva em classes de componente`

---

### T6: Fonte única / congelar `application.css` ao legado

**What:** Garantir definição única dos estilos do app ativo: confirmar que nenhuma página ativa carrega regra duplicada, rotular `application.css` como exclusivo do legado `games/*`, e remover qualquer resíduo de classe morta nas views migradas.
**Where:**
- `app/assets/stylesheets/application.css` (cabeçalho/comentário "legado games/*"; sem refatorar games)
- `app/assets/stylesheets/torcedor_maluco.css` (organização em camadas comentadas)
- varredura nas views ativas
**Depends on:** T4, T5
**Reuses:** estado atual (app ativo já só carrega `torcedor_maluco.css`)
**Requirement:** RESP-11

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `grep` por `.btn-play`/`.opt`/`.logo-sticker` mostra definição única para o app ativo (cópias remanescentes só em `application.css`, marcado como legado)
- [ ] `application.css` tem comentário explícito "exclusivo do layout `application` (legado `games/*`) — não usar em páginas ativas"
- [ ] `torcedor_maluco.css` organizado em camadas comentadas (Tokens · Palco/Backdrop · Header · Componentes · Telas · Conteúdo)
- [ ] Nenhuma classe utilitária Tailwind morta nas views ativas (confirma T4/T5)
- [ ] Deferred registrado em STATE.md: "retirar `games/*` + `application.css`"
- [ ] `bin/rails test` verde

**Tests:** none · **Gate:** quick
**Commit:** `refactor(design): fonte única de estilo; congela application.css ao legado`

---

### T7: Acabamento premium do backdrop ≥1440px [P] (P3 — opcional)

**What:** Refinar o backdrop em telas muito grandes (profundidade/vinheta/elementos sutis) mantendo contraste e foco no palco. Polimento — não bloqueia o lançamento.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (`@media (min-width:1440px)`)
**Depends on:** T1
**Reuses:** backdrop de T1
**Requirement:** RESP-13

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] `@media (min-width:1440px)` adiciona acabamento ao backdrop (gradiente/vinheta/detalhe), mantendo contraste
- [ ] Palco se destaca claramente em 1920×1080
- [ ] `bin/rails test` verde
- [ ] Verificação visual em 1920×1080

**Tests:** none (CSS) · **Gate:** quick + visual
**Commit:** `feat(design): acabamento premium do backdrop em telas grandes`

---

### T8: Verificação final — matriz de breakpoints + suíte verde

**What:** Rodar a matriz visual completa em todas as superfícies e confirmar não-regressão funcional. Fecha os Success Criteria da spec.
**Where:** verificação (sem código novo); ajustes pontuais de calibragem se necessário
**Depends on:** T2, T3, T4, T5, (T6, T7)
**Reuses:** Claude_Preview/Chrome para os breakpoints
**Requirement:** RESP-03 (não-regressão), todos os Success Criteria

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] Matriz 320/390/768/1024/1440/1920 verificada em: home, pergunta, resultado, sem-energia, ranking, nickname
- [ ] Checklist por tela: sem rolagem horizontal · mobile sem regressão · backdrop nas telas grandes · tipografia escalando · paisagem 740×360 jogável
- [ ] `bin/rails test:all` verde (inclui system)
- [ ] (Opcional) 1 system smoke test renderizando as superfícies em largura desktop — decidir custo/benefício aqui
- [ ] STATE.md atualizado (decisões da feature) e ROADMAP marca a sprint de UI

**Tests:** system (opcional smoke) · **Gate:** full (`bin/rails test:all`) + matriz visual
**Commit:** `chore(design): verificação responsiva multi-tela e ajustes de calibragem`

---

## Parallel Execution Map

```
Phase 1 (Sequential):
  T1

Phase 2 (Parallel — todos dependem só de T1):
  T1 ──→ T2 [P]
  T1 ──→ T3 [P]
  T1 ──→ T4 [P]
  T1 ──→ T5 [P]
  T1 ──→ T7 [P] (opcional)

Phase 3 (Sequential):
  T4, T5 → T6
  T2,T3,T4,T5,T6,T7 → T8
```

> Com um único executor, a ordem natural é T1 → T2 → T3 → T4 → T5 → T6 → (T7) → T8.
> Atenção a conflito de merge: T2–T7 editam o mesmo arquivo (`torcedor_maluco.css`) em seções diferentes — se rodar `[P]` com sub-agentes, integrar por seção/camada para evitar colisão.

---

## Validação Pré-Aprovação

### Check 1 — Granularidade

| Task | Escopo | Status |
|------|--------|--------|
| T1 | Tokens + palco + backdrop (fundação coesa) | ✅ |
| T2 | Fluidez dos componentes do jogo | ✅ |
| T3 | Confete + paisagem/altura | ✅ coeso (mesmo concern: viewport/altura) |
| T4 | 1 tela (ranking) migrada | ✅ |
| T5 | 1 tela (nickname) migrada | ✅ |
| T6 | Consolidação/fonte única | ✅ |
| T7 | Polimento ≥1440 (P3) | ✅ pequeno/opcional |
| T8 | Verificação final | ✅ |

### Check 2 — Diagrama × Dependências

| Task | Depends on | Diagrama mostra | Status |
|------|-----------|-----------------|--------|
| T1 | None | — | ✅ |
| T2 | T1 | T1→T2 [P] | ✅ |
| T3 | T1 | T1→T3 [P] | ✅ |
| T4 | T1 | T1→T4 [P] | ✅ |
| T5 | T1 | T1→T5 [P] | ✅ |
| T6 | T4, T5 | T4,T5→T6 | ✅ |
| T7 | T1 | T1→T7 [P] | ✅ |
| T8 | T2..T7 | →T8 | ✅ |

### Check 3 — Co-localização de testes (matriz TESTING.md)

| Task | Camada | Matriz exige | Task diz | Status |
|------|--------|--------------|----------|--------|
| T1–T7 | CSS / views estáticas | none | none (+ visual) | ✅ |
| T8 | Tela no navegador (smoke opcional) | system | system (opcional) | ✅ |

### Check 4 — Cobertura de requisitos

| Req | Task | | Req | Task |
|-----|------|-|-----|------|
| RESP-01 | T1 | | RESP-09 | T3 |
| RESP-02 | T1 | | RESP-10 | T3 |
| RESP-03 | T1/T8 | | RESP-11 | T6 |
| RESP-04 | T1 | | RESP-12 | T1 |
| RESP-05 | T2 | | RESP-13 | T7 |
| RESP-06 | T2 | | RESP-14 | T3 |
| RESP-07 | T4 | | RESP-15 | T3 |
| RESP-08 | T5 | | | |

**Cobertura:** 15/15 requisitos mapeados a tasks. ✅

---

## Ferramentas e Skills antes de Executar

- **CSS/views:** ferramentas nativas de edição + Bash (`bin/rails test`). Sem MCP externo obrigatório.
- **Verificação visual (T1–T3, T7, T8):** MCP de preview/navegador (`Claude_Preview` ou `Claude_in_Chrome`) para a matriz de breakpoints — confirmar com o dono qual usar.
- Commits atômicos por tarefa, localmente (como no M1/M2).

# Redesign Visual (Landing + Ranking + retheme global) — Tasks

**Design:** `.specs/features/redesign-visual/design.md`
**Spec:** `.specs/features/redesign-visual/spec.md`
**Testing:** `.specs/codebase/TESTING.md` (views estáticas → none · helper/lógica → unit · tela no navegador → system)
**Status:** Ready for execution
**Baseline:** suíte atual deve permanecer verde (96 testes); feature majoritariamente de apresentação

---

## Execution Plan

### Phase 1: Fundação — retheme por tokens (Sequential)

```
T1 (tokens paleta + fonte + chip contornado)  ← tudo herda disto
```

### Phase 2: Helper + telas (após T1; T3/T4 paralelizáveis)

```
T1 ──→ T2 (helper avatar + testes)  ← pré-requisito de T3 e T4
T2 ──→ T3 [P] (Landing: hero, saudação, prova social, gbtn)  + T1b controller
T2 ──→ T4 [P] (Ranking: band, pódio, lista, loginbar)
```

### Phase 3: Verificação (Sequential)

```
T3, T4 → T5 (não-regressão quiz/resultado + matriz visual + suíte verde)
```

---

## Task Breakdown

### T1: Retheme por tokens (paleta + fonte Baloo 2 + chip contornado)

**What:** Atualizar a paleta no `:root`, introduzir tokens de fonte (`--font-display`/`--font-body`), trocar o
`<link>` do Google Fonts para Baloo 2, substituir `'Fredoka'` → `var(--font-display)` no stylesheet e tornar o
chip "COPA 2026" contornado. Fundação que cascateia para todas as telas.
**Where:**
- `app/assets/stylesheets/torcedor_maluco.css` (`:root`, `body`, `.hdr-tag`, replace_all de `'Fredoka'`)
- `app/views/layouts/matches.html.erb` (linha 16 — `<link>` de fontes)
**Depends on:** None
**Reuses:** `:root` existente (tokens `--fs-*`/`--stage-max` permanecem)
**Requirement:** RDS-01, RDS-02, RDS-03

**Tools:** MCP: Claude_Preview/Chrome (verificação visual) · Skill: NONE

**Done when:**
- [ ] Paleta atualizada (`--verde:#16a34a`+`--verde-2`/`--verde-esc`, `--amarelo:#ffd000`, `--amarelo-esc:#f2b500`, `--azul:#13286b`+`--azul-esc`, `--ink:#10204a`, `--muted:#5a6a86`, `--certo-bg`/`--errado-bg`, `--link`/`--free`)
- [ ] `--font-display:'Baloo 2',sans-serif` e `--font-body:'Nunito',system-ui,sans-serif` em `:root`
- [ ] `<link>` carrega `Baloo+2:wght@600;700;800` (+ Nunito); Fredoka removido do import
- [ ] `'Fredoka',sans-serif` substituído por `var(--font-display)` (replace_all) e `body` → `var(--font-body)`
- [ ] `.hdr-tag` contornado (fundo transparente, borda+texto amarelos)
- [ ] `bin/rails test` verde
- [ ] Visual: home/quiz/resultado/ranking renderizam com nova paleta/fonte; chip contornado

**Tests:** none (CSS) · **Gate:** quick (`bin/rails test`) + visual
**Commit:** `feat(redesign): retheme global — paleta, Baloo 2 e chip de marca contornado`

---

### T2: Helper de avatar (monograma + cor determinística) + testes

**What:** Criar `avatar_monogram(nickname)` e `avatar_color(seed)` no ApplicationHelper, com a classe CSS
`.avatar` (e modificador de pódio). Pré-requisito visual de Landing e Ranking.
**Where:**
- `app/helpers/application_helper.rb` (helpers)
- `app/assets/stylesheets/torcedor_maluco.css` (`.avatar`, `.avatar--podium`)
- `test/helpers/application_helper_test.rb` (testes unit)
**Depends on:** T1
**Reuses:** tokens de cor/fonte de T1
**Requirement:** RDS-15

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `avatar_monogram(nickname)` retorna inicial upcased; fallback `"?"` p/ vazio/"Anônimo"; trata grapheme não-latino sem erro
- [ ] `avatar_color(seed)` é determinístico (mesma seed → mesma cor; paleta fixa de tons)
- [ ] `.avatar` (círculo, inicial centralizada `var(--font-display)`) + `.avatar--podium` (borda amarela 3px)
- [ ] Teste unit cobre: inicial correta, fallback, determinismo da cor
- [ ] `bin/rails test` verde · `bin/rubocop` limpo no helper

**Tests:** unit (helper) · **Gate:** quick
**Commit:** `feat(redesign): helper de avatar monograma determinístico`

---

### T3: Landing — hero, saudação, prova social (contagem real), botão Google [P]

**What:** Reestruturar a home conforme o handoff: hero Baloo 2 sem rotação, saudação condicional com apelido,
meta row, prova social com contagem real e botão Google estilizado. Inclui o `@players_today` no controller.
**Where:**
- `app/views/matches/_home.html.erb` (markup novo)
- `app/controllers/matches_controller.rb` (`@players_today` em `#show` quando `:home`)
- `app/assets/stylesheets/torcedor_maluco.css` (`.logo`/`.logo-sticker` sem rotação + Baloo 2 + sombra 3D; `.greeting`, `.home-meta`, `.social`, `.social-avatars`, `.gbtn`)
- `test/controllers/matches_controller_test.rb` ou `test/integration/*` (cobre `@players_today`)
**Depends on:** T2
**Reuses:** `.home-card`, `.btn-play`, `.nick`, fluxo de edição de apelido, `.avatar` (T2), OAuth path, `GameResult`
**Requirement:** RDS-04, RDS-05, RDS-06, RDS-07, RDS-08

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] Hero: badge azul sem rotação + título 2 linhas Baloo 2 com sombra 3D azul (rotação zerada em `.logo`/`.logo-sticker`)
- [ ] Saudação `.greeting` condicional (logado: `current_user.nickname`; convidado: `session[:nickname]`; some se ausente)
- [ ] Meta row `.home-meta` (trocar apelido + "● Grátis e sem anúncios")
- [ ] `@players_today = GameResult.where("played_at >= ?", Time.current.beginning_of_day).distinct.count(:user_id)`; prova social renderiza só se `> 0` (avatares-monograma + "+N torcedores já jogaram hoje")
- [ ] Botão Google `.gbtn` (logo SVG) → `user_google_oauth2_omniauth_authorize_path` (POST, turbo:false)
- [ ] Teste cobre `@players_today` (conta distintos do dia; 0 quando vazio)
- [ ] `bin/rails test` verde · `bin/rubocop` limpo no controller
- [ ] Visual: logado / convidado-com-apelido / convidado-sem-apelido; N>0 e N=0

**Tests:** integration (`@players_today`) · **Gate:** full (`bin/rails test:all`) + visual
**Commit:** `feat(redesign): landing com saudação, prova social real e login Google estilizado`

---

### T4: Ranking — band header, pódio top-3, lista nova, faixa de login [P]

**What:** Reestruturar o ranking: band verde com voltar + cabeçalho, pódio top-3 (ordem 2-1-3, adaptativo a
< 3), lista de linhas redesenhada com destaque amarelo do usuário, e faixa de login no rodapé para convidado.
Preserva toggle de período, badges e estado vazio. Sem mexer em model/controller de ranking.
**Where:**
- `app/views/ranking/index.html.erb` (band, rankHead, pódio, loginbar; remover `.rank-cta` do topo)
- `app/views/ranking/_ranking_list.html.erb` (linha nova + avatar)
- `app/assets/stylesheets/torcedor_maluco.css` (`.band`, `.band-back`, `.band-title`, `.rankHead`, `.podium`, `.pod`/`.pod.p1/p2/p3`, `.pod-bar`, `.row`/`.row.me`/`.row-pos`/`.row-name`/`.row-sub`/`.row-pts`, `.loginbar`)
**Depends on:** T2
**Reuses:** `@entries`/`Quiz::Leaderboard::Entry` (inalterado), `.rank-tabs`, `.rank-empty`, `.avatar` (T2), OAuth path
**Requirement:** RDS-09, RDS-10, RDS-11, RDS-12, RDS-13, RDS-14, RDS-17, RDS-18

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] `.band` substitui `matches/header`+`.rank-title`: voltar "‹" (→ `root_path`) + "🏆 RANKING" centralizado + espaço-fantasma
- [ ] `.rankHead` ("A torcida de hoje" + "Top jogadores · Copa 2026") sobre o verde
- [ ] Pódio: `top=@entries.first(3)`, render `[top[1],top[0],top[2]].compact` (avatar borda amarela, nome, pontos, barras 62/46/34); adapta a 1/2 entradas sem erro
- [ ] Lista: posição · avatar-monograma · nome + sub-label (`entry.detail`) · pontos navy; badges preservados; 👑 removido da lista
- [ ] `.row.me`: borda amarela, fundo `#fffdf0`, sombra inferior, posição azul (substitui destaque verde)
- [ ] `.loginbar` azul no rodapé só p/ convidado; logado não vê; `.rank-cta` do topo removido
- [ ] Toggle de período (`.rank-tabs`) e estado vazio (`.rank-empty`) preservados
- [ ] `bin/rails test` verde
- [ ] Visual: 0 / 2 / 5 jogadores; logado (sem loginbar) e convidado (com); toggle e badges OK

**Tests:** none (view) · **Gate:** quick + visual
**Commit:** `feat(redesign): ranking com pódio, lista redesenhada e faixa de login`

---

### T5: Verificação final — herança de tema + matriz visual + suíte verde

**What:** Confirmar que quiz e resultado herdaram o tema sem regressão e rodar a matriz visual completa das duas
telas-foco e dos casos de borda. Fecha os Success Criteria da spec.
**Where:** verificação (sem código novo); ajustes pontuais de calibragem se necessário
**Depends on:** T3, T4
**Reuses:** Claude_Preview/Chrome
**Requirement:** RDS-16, todos os Success Criteria

**Tools:** MCP: Claude_Preview/Chrome · Skill: NONE

**Done when:**
- [ ] Jogar uma partida: pergunta (estados `.opt.*`, timer, placar) e resultado (score, recap, confete, badges) coerentes com o novo tema, sem quebra
- [ ] Landing verificada em ~390px e largura grande (logado/convidado, N>0/N=0)
- [ ] Ranking verificado em ~390px e largura grande (0/2/5 jogadores; loginbar condicional; toggle; badges)
- [ ] Sem rolagem horizontal; chip contornado em todas as telas
- [ ] `bin/rails test:all` verde · `bin/rubocop` limpo
- [ ] STATE.md atualizado (decisões da feature) e ROADMAP marca o redesign

**Tests:** system (smoke opcional) · **Gate:** full (`bin/rails test:all`) + matriz visual
**Commit:** `chore(redesign): verificação de herança de tema e ajustes de calibragem`

---

## Parallel Execution Map

```
Phase 1 (Sequential):
  T1

Phase 2:
  T1 ──→ T2 (helper — pré-requisito visual)
  T2 ──→ T3 [P]  (Landing)
  T2 ──→ T4 [P]  (Ranking)

Phase 3 (Sequential):
  T3, T4 → T5
```

> Com um único executor, a ordem natural é T1 → T2 → T3 → T4 → T5.
> **Conflito de merge:** T1–T4 editam `torcedor_maluco.css` em seções diferentes. Se rodar T3/T4 `[P]` com
> sub-agentes, integrar por seção/camada (Landing vs Ranking) para evitar colisão; T1 e T2 já terão fechado
> tokens e `.avatar` antes.

---

## Validação Pré-Aprovação

### Check 1 — Granularidade

| Task | Escopo | Status |
|------|--------|--------|
| T1 | Retheme por tokens (fundação coesa) | ✅ |
| T2 | Helper de avatar + testes | ✅ pequeno/coeso |
| T3 | 1 tela (Landing) + controller da prova social | ✅ |
| T4 | 1 tela (Ranking) — band/pódio/lista/loginbar | ✅ coeso (mesma superfície) |
| T5 | Verificação final | ✅ |

### Check 2 — Diagrama × Dependências

| Task | Depends on | Diagrama mostra | Status |
|------|-----------|-----------------|--------|
| T1 | None | — | ✅ |
| T2 | T1 | T1→T2 | ✅ |
| T3 | T2 | T2→T3 [P] | ✅ |
| T4 | T2 | T2→T4 [P] | ✅ |
| T5 | T3, T4 | T3,T4→T5 | ✅ |

### Check 3 — Co-localização de testes (matriz TESTING.md)

| Task | Camada | Matriz exige | Task diz | Status |
|------|--------|--------------|----------|--------|
| T1 | CSS / view estática | none | none (+ visual) | ✅ |
| T2 | helper (lógica) | unit | unit | ✅ |
| T3 | view + controller (query) | none + integration | integration (+ visual) | ✅ |
| T4 | views estáticas | none | none (+ visual) | ✅ |
| T5 | tela no navegador | system | system (smoke opcional) | ✅ |

### Check 4 — Cobertura de requisitos

| Req | Task | | Req | Task |
|-----|------|-|-----|------|
| RDS-01 | T1 | | RDS-10 | T4 |
| RDS-02 | T1 | | RDS-11 | T4 |
| RDS-03 | T1 | | RDS-12 | T4 |
| RDS-04 | T3 | | RDS-13 | T4 |
| RDS-05 | T3 | | RDS-14 | T4 |
| RDS-06 | T3 | | RDS-15 | T2 |
| RDS-07 | T3 | | RDS-16 | T5 |
| RDS-08 | T3 | | RDS-17 | T4 |
| RDS-09 | T4 | | RDS-18 | T4 |

**Cobertura:** 18/18 requisitos mapeados a tasks. ✅

---

## Ferramentas e Skills antes de Executar

- **CSS/views/helper:** ferramentas nativas de edição + Bash (`bin/rails test`, `bin/rubocop`). Sem MCP obrigatório.
- **Verificação visual (T1, T3, T4, T5):** MCP de preview/navegador (`Claude_Preview` ou `Claude_in_Chrome`) —
  confirmar com o dono qual usar (atenção ao login Google em localhost: redirect URI precisa estar autorizada).
- **Asset do logo Google:** SVG inline copiado do protótipo (`landing.html`) — sem novo asset externo.
- Commits atômicos por tarefa, localmente (como no M1/M2).

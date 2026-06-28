# Redesign Visual (Landing + Ranking + retheme global) — Design

**Spec:** `.specs/features/redesign-visual/spec.md`
**Status:** Approved
**Decisões de base (usuário, 2026-06-23):**
1. **Escopo:** retheme do **app inteiro** (tokens globais paleta + Baloo 2); quiz/resultado herdam por cascata.
2. **Avatares:** **monograma** (inicial do apelido), determinístico — sem dado novo.
3. **Prova social:** **contagem real** de jogadores distintos do dia.

---

## Architecture Overview

A feature é **CSS de componentes orientado a tokens** (mesma base da feature `design-responsivo`), com duas
camadas de trabalho:

1. **Retheme por tokens** (`:root` de `torcedor_maluco.css`) — atualizar a paleta e introduzir tokens de
   fonte (`--font-display`/`--font-body`). Trocar `'Fredoka'` → `var(--font-display)` no stylesheet inteiro e
   o `<link>` do Google Fonts no layout. Como `:root` é a fonte única de tokens do app ativo, o novo visual
   **cascateia** para header, quiz e resultado sem editá-los.
2. **Reestruturação de 2 telas** (Landing + Ranking) — novo markup ERB + classes de componente novas,
   reusando a estrutura de dados existente (nenhuma mudança de query/contrato).

Único toque de Ruby: um `@players_today` no controller (prova social) e um helper de avatar (apresentação).

```mermaid
graph TD
    L["layout matches.html.erb"] -->|link Baloo 2| CSS["torcedor_maluco.css (fonte única)"]
    CSS --> TOK["Camada Tokens (:root) — paleta + fontes"]
    TOK -.cascata.-> HDR["header · quiz · resultado (herdam)"]
    TOK --> LAND["Landing (_home) — hero, saudação, prova social, gbtn"]
    TOK --> RANK["Ranking (index + _ranking_list) — band, pódio, linhas, loginbar"]
    CTRL["MatchesController#show"] -->|@players_today| LAND
    HLP["ApplicationHelper avatar_monogram/avatar_color"] --> LAND
    HLP --> RANK
    LB["Quiz::Leaderboard (inalterado)"] --> RANK
```

> Diagrama inline (mermaid). A skill `mermaid-studio` não está instalada — para render SVG/validação, vale
> instalá-la (aviso único nesta sessão).

---

## Discovered State (pré-condições)

| Fato (verificado no código) | Implicação |
|------|-----------|
| `:root` em `torcedor_maluco.css:8-31` já centraliza paleta + tokens responsivos (`--fs-*`, `--stage-max`) | Retheme = editar esse bloco; tokens responsivos da feature anterior permanecem intactos |
| `'Fredoka',sans-serif` aparece ~40× no stylesheet (display) | Introduzir `--font-display` e fazer replace_all resolve em 1 ponto e habilita troca futura trivial |
| `body{font-family:'Nunito'...}` (linha 35) | Vira `var(--font-body)` |
| Layout `matches.html.erb:16` carrega Fredoka+Nunito no `<link>` | Trocar Fredoka por Baloo 2 no import |
| `_home.html.erb` já tem `.home/.home-hero/.home-card/.btn-play/.nick/.free-line` + edição de apelido | Reusar esqueleto; adicionar saudação, meta row, prova social, gbtn; tirar rotação do `.logo` |
| `.logo{transform:rotate(-3deg)}` e `.logo-sticker{transform:rotate(2deg)}` (linhas 185/191) | Handoff remove rotação — zerar transform |
| Header compartilhado `.hdr` com `.hdr-tag` amarelo preenchido (linhas 72-75) | Chip vira contornado (regra de marca) — afeta todas as telas, barato e on-brand |
| `ranking/index.html.erb` renderiza `matches/header` + `.rank-title` + `.rank-tabs` + `.rank-cta` (topo) | Substituir header por band com voltar; mover CTA p/ `.loginbar` no rodapé; manter `.rank-tabs` |
| `_ranking_list.html.erb` itera `Quiz::Leaderboard::Entry` (rank, nickname, masked_email, value, detail, badges) | Tem tudo p/ linha nova e pódio; **não há avatar** → monograma derivado do nickname |
| `Quiz::Leaderboard.for` já entrega entries ordenados; `RankingController#index` monta `@entries/@periods/@period` | Pódio = `@entries.first(3)`; **nenhuma** mudança de model/controller de ranking |
| Só usuários logados geram `GameResult` (em `MatchesController#next_question`) | "Torcedores hoje" = usuários distintos com `GameResult` hoje — número honesto |
| `GameResult` tem `played_at` (usado em testes/leaderboard) | Base da contagem `@players_today` |

---

## Code Reuse Analysis

### Existing Components to Leverage

| Component | Location | How to Use |
|-----------|----------|------------|
| `:root` (tokens) | `torcedor_maluco.css:8` | Atualizar paleta + adicionar `--font-display`/`--font-body` (fonte única) |
| Esqueleto da home | `app/views/matches/_home.html.erb` | Reusar `.home/.home-hero/.home-card`; adicionar blocos novos |
| `.btn-play`, `.nick`, `.free-line`, `.field` | `torcedor_maluco.css` | Reaproveitar; CTA/inputs/campo só reestilizam via tokens |
| Estrutura de ranking (ERB + dados) | `ranking/index.html.erb`, `_ranking_list.html.erb` | Reescrever markup reusando `@entries`/`Entry` — sem mexer na query |
| `Quiz::Leaderboard` | `app/models/quiz/leaderboard.rb` | **Inalterado** — pódio e lista consomem os `Entry` existentes |
| `RankingController#index` | `app/controllers/ranking_controller.rb` | **Inalterado** — `@entries.first(3)` cobre o pódio |
| OAuth path | `user_google_oauth2_omniauth_authorize_path` | Reusar nos botões Google (Landing gbtn + loginbar) |
| `GameResult` | `app/models/game_result.rb` | Fonte da contagem `@players_today` |
| ApplicationHelper | `app/helpers/application_helper.rb` | Hospedar `avatar_monogram`/`avatar_color` |

### Integration Points

| System | Integration Method |
|--------|--------------------|
| Asset pipeline | `stylesheet_link_tag "torcedor_maluco"` já no layout; só muda o `<link>` de fontes |
| Turbo Frames (`#match`) | Landing é renderizada dentro de `#match`; contrato Turbo inalterado |
| Devise/OmniAuth | Botões Google via POST (`button_to`, `turbo:false`) — padrão já usado no app |
| `Quiz::Leaderboard` | Consumido como hoje; pódio é só fatiamento de `@entries` na view |

> Nota de débito (STATE.md): `games/*` + `application.css` permanecem legado/deferred — não tocamos.

---

## Components

### 1. Camada de Tokens — retheme (`:root`)
- **Purpose:** Fonte única de cor/fonte; mudar tema = editar aqui (RDS-01, RDS-02).
- **Location:** `torcedor_maluco.css` (`:root`, `body`).
- **Mudanças:**
  - Paleta: `--verde:#16a34a` (+`--verde-2:#13923f`, `--verde-esc:#0c7a33`), `--amarelo:#ffd000`,
    `--amarelo-esc:#f2b500`, `--azul:#13286b`, `--azul-esc:#0e1f53`, `--ink:#10204a`, `--muted:#5a6a86`,
    `--linha:#eceff3`, `--certo/-bg`, `--errado/-bg`, `--link/-bd`, `--free:#108a3e`.
  - Fontes: `--font-display:'Baloo 2',sans-serif;` `--font-body:'Nunito',system-ui,sans-serif;`.
  - `replace_all`: `'Fredoka',sans-serif` → `var(--font-display)`; `body` font → `var(--font-body)`.
- **Reuses:** o `:root` existente (tokens responsivos `--fs-*`/`--stage-max` ficam).

### 2. Chip de marca contornado (`.hdr-tag`)
- **Purpose:** Liberar amarelo para o CTA (RDS-03).
- **Mudança:** fundo transparente, `border:2px solid var(--amarelo)`, texto `var(--amarelo)`. Afeta o header
  compartilhado (todas as telas) — deliberado e on-brand.

### 3. Landing (`_home.html.erb` + classes novas)
- **Purpose:** Hero novo + cartão com saudação/prova social/Google (RDS-04..RDS-08).
- **Location:** `app/views/matches/_home.html.erb`; CSS `.logo`/`.logo-sticker` (zerar rotação, Baloo 2, sombra 3D),
  novas `.greeting`, `.home-meta`, `.social`, `.social-avatars`, `.gbtn`.
- **Hero:** badge azul `box-shadow:0 6px 0 var(--azul-esc)` sem rotação; título 2 linhas uppercase com a
  sombra 3D do README (`0 3px 0 navy, 0 4px 0 navy, 3px 4px 0 navy, -3px 4px 0 navy, 0 7px 14px rgba(0,0,0,.25)`).
- **Cartão:**
  - Saudação `<p class="greeting">` condicional (apelido logado/convidado).
  - CTA `.btn-play` (radius/shadow já em tokens).
  - Meta row `.home-meta` (space-between): "Trocar apelido" (reusa `root_path(edit_nick: 1)`) + "● Grátis…".
  - Prova social `.social` (render só se `@players_today.to_i > 0`): 3 avatares-monograma sobrepostos + texto.
  - Botão Google `.gbtn` (logo SVG inline copiado do protótipo) → `user_google_oauth2_omniauth_authorize_path` (POST).
- **Reuses:** `.home-card`, `.btn-play`, `.nick`, fluxo de edição de apelido.

### 4. Ranking — band header + cabeçalho (`index.html.erb`)
- **Purpose:** Navegação e contexto sobre o verde (RDS-09, RDS-10).
- **Location:** `app/views/ranking/index.html.erb`; CSS `.band`, `.band-back`, `.band-title`, `.rankHead`.
- **Mudança:** substituir `render "matches/header"` + `.rank-title` por `.band` (voltar "‹" → `root_path`;
  título centralizado; espaço-fantasma à direita) e `.rankHead` ("A torcida de hoje" + subtítulo).
- **Mantém:** `.rank-tabs` (toggle de período) e o estado vazio (`.rank-empty`).

### 5. Ranking — Pódio (`index.html.erb` + helper de ordenação)
- **Purpose:** Top-3 destacado, ordem visual 2-1-3 (RDS-11, RDS-18).
- **Location:** bloco no `index.html.erb`; CSS `.podium`, `.pod`, `.pod.p1/p2/p3`, `.pod-bar`, `.avatar`.
- **Lógica de view:** `top = @entries.first(3)`; ordem de render `[top[1], top[0], top[2]].compact` (defensivo p/
  < 3). Cada `.pod`: avatar (monograma, borda amarela), nome curto, pontos, barra (1º 62px amarela / 2º 46px /
  3º 34px translúcidas).

### 6. Ranking — Lista nova (`_ranking_list.html.erb`)
- **Purpose:** Linhas redesenhadas + destaque do usuário (RDS-12, RDS-13, RDS-17).
- **Location:** `app/views/ranking/_ranking_list.html.erb`; CSS `.row`, `.row.me`, `.row-pos`, `.row-name`,
  `.row-sub`, `.row-pts`, `.avatar`.
- **Linha:** posição (Baloo 2, muted) · avatar-monograma · nome (800) + sub-label (`entry.detail`) · pontos
  (Baloo 2 navy). Badges de `entry.badges` numa linha sob o nome (preservar feature M2).
- **`.row.me`:** borda `2px var(--amarelo)`, fundo `#fffdf0`, `box-shadow:0 4px 0 var(--amarelo-esc)`, posição azul.
  Remover o 👑 da lista (o pódio já destaca o 1º).

### 7. Ranking — Faixa de login (`.loginbar`)
- **Purpose:** Convidar convidado ao OAuth (RDS-14).
- **Location:** rodapé do `index.html.erb` (só `unless user_signed_in?`); CSS `.loginbar`.
- **Mudança:** mover a CTA do topo (`.rank-cta`) para uma faixa azul no rodapé ("Entre pra valer ponto. Salve
  seu recorde…" + botão "Entrar" com logo Google). Remover `.rank-cta` do topo.

### 8. Avatar monograma (helper + `.avatar`)
- **Purpose:** Identidade visual sem dado novo (RDS-15).
- **Location:** `app/helpers/application_helper.rb`; CSS `.avatar` (círculo, inicial centralizada Baloo 2),
  modificador `.avatar--podium` (borda amarela 3px).
- **Interfaces:**
  - `avatar_monogram(nickname)` → primeiro grapheme upcased; fallback `"?"` p/ vazio/"Anônimo".
  - `avatar_color(seed)` → cor determinística a partir de `hash` do seed (paleta fixa de N tons), p/ variar fundos.
- **Reuses:** consumido em pódio, lista e prova social da Landing.

### 9. Prova social — contagem real (`MatchesController#show`)
- **Purpose:** Número honesto de jogadores do dia (RDS-07).
- **Location:** `app/controllers/matches_controller.rb#show` (só quando `@screen == :home`).
- **Implementação:** `@players_today = GameResult.where("played_at >= ?", Time.current.beginning_of_day)
  .distinct.count(:user_id)`. View renderiza a prova social só se `> 0`.

---

## Data Models

Não se aplica — **sem migrations, sem coluna nova, sem mudança de modelo**. `avatar` é derivado (monograma);
`@players_today` é uma agregação de leitura sobre `GameResult`. Contrato de `Quiz::Leaderboard` inalterado.

---

## Token Reference (retheme)

| Token | De (atual) | Para (handoff) |
|-------|-----------|----------------|
| `--verde` | `#009C3B` | `#16a34a` (+`--verde-2:#13923f`, `--verde-esc:#0c7a33`) |
| `--amarelo` | `#FFDF00` | `#ffd000` |
| `--amarelo-esc` | `#f4c800` | `#f2b500` |
| `--azul` | `#002776` | `#13286b` (+`--azul-esc:#0e1f53`) |
| `--ink` | `#0a1733` | `#10204a` |
| `--muted` | — (cores soltas `#6b7180`/`#9499a8`) | `#5a6a86` (consolidar onde fizer sentido) |
| `--errado` | `#e23636` | `#e23b3b` (+`--errado-bg:#fdeded`) |
| `--certo` | `#16a34a` | `#16a34a` (+`--certo-bg:#e9faf0`) |
| `--font-display` | `'Fredoka'` (hardcoded) | `'Baloo 2'` (token) |
| `--font-body` | `'Nunito'` (hardcoded) | `'Nunito'` (token) |
| `--link` / `--free` | — | `#2b56c4` (`--link-bd:#c5d2f2`) / `#108a3e` |

> `--creme:#fbfbf4` permanece (fundo das telas de jogo). Sombra 3D do título amarelo conforme README §"Sombra 3D".

---

## Error Handling / Graceful Degradation

| Cenário | Tratamento | Impacto |
|---------|-----------|---------|
| Ranking com < 3 jogadores | `[top[1], top[0], top[2]].compact` no pódio | Só colunas existentes, sem erro (RDS-18) |
| Ranking vazio | Estado vazio atual preservado; band/pódio não renderizam lista | Sem quebra (RDS-18) |
| Convidado sem `session[:nickname]` | Saudação condicional (`if nome.present?`) | Landing sem saudação, sem erro |
| `@players_today == 0` | Prova social renderizada só se `> 0` | Sem "+0 torcedores" |
| Apelido vazio/"Anônimo"/grapheme não-latino | `avatar_monogram` com fallback `"?"`/primeiro grapheme | Avatar sempre renderiza |
| Baloo 2 não carrega (rede) | `var(--font-display)` cai em `sans-serif` | Degradação tipográfica mínima |

---

## Tech Decisions (only non-obvious ones)

| Decisão | Escolha | Racional |
|---------|---------|----------|
| Escopo do retheme | **App inteiro** via tokens globais | Decisão do dono; consistência; quiz/resultado herdam sem editar (menor superfície de mudança) |
| Tipografia | Tokens `--font-display`/`--font-body` + `replace_all` de `'Fredoka'` | Altitude correta: troca de fonte vira 1 linha no futuro; replace é mecânico e de baixo risco |
| Avatar | **Monograma** determinístico (helper), não emoji/imagem | Decisão do dono; sem dado novo, sem migration, estável por usuário |
| Cor do avatar | Determinística por hash do nickname | Variedade visual sem persistência; mesma seed → mesma cor |
| Prova social | **Contagem real** de jogadores distintos hoje | Decisão do dono; honesto. Render condicional evita número fraco (N=0) |
| Chip "COPA 2026" | Contornado app-wide | Regra de marca do handoff (amarelo só no CTA); barato e consistente |
| Quiz/resultado | Só herdam tokens (não reescrever markup) | Foco do handoff é Landing+Ranking; minimiza risco de regressão |
| Ranking model/controller | **Inalterado** | `Quiz::Leaderboard` já entrega o necessário; pódio é fatiamento de view |
| `games/*` + `application.css` | Permanecem legado/deferred | Fora de escopo (consistente com feature `design-responsivo`) |

---

## Verification Strategy

Conforme `.specs/codebase/TESTING.md` (views/partials estáticas → **none**; helper/lógica → **unit**;
tela no navegador → **system**):

- **Helper de avatar (`avatar_monogram`/`avatar_color`):** teste **unit** — inicial correta, fallback "?",
  cor determinística (mesma seed → mesma cor).
- **`@players_today` (controller):** coberto por teste de **integration** leve no `MatchesController#show` —
  conta jogadores distintos do dia (e 0 quando não há). Pode ser unit no GameResult se preferir isolar a query.
- **Views (Landing/Ranking/pódio/linhas/loginbar):** **none** (apresentação) → verificação **visual**.
- **Não-regressão:** `bin/rails test` verde (96 testes) + `bin/rubocop` limpo nos arquivos Ruby (controller, helper).
- **Verificação visual (preview/navegador):** mobile (~390px) e largura grande, em:
  - Landing: logado / convidado-com-apelido / convidado-sem-apelido; prova social com N>0 e N=0.
  - Ranking: 0 / 2 / 5 jogadores; logado (sem loginbar) e convidado (com loginbar); toggle e badges.
  - Quiz + resultado: herança de tema sem quebra.

---

## Resolved Questions (2026-06-23)

1. **Escopo:** app inteiro (tokens globais) — quiz/resultado herdam.
2. **Avatares:** monograma (inicial), determinístico.
3. **Prova social:** contagem real de jogadores do dia (render condicional se > 0).

**Status:** Approved.

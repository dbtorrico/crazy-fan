# Ranking Semanal — Design

**Spec:** `.specs/features/ranking-semanal/spec.md`
**Status:** Approved (decisões do dono em 2026-06-14)

---

## Architecture Overview

A feature troca o ranking atual (por partida) por um **ranking por período agregado** e deixa o
código **pluggável** para novos períodos. Reaproveita a tabela `game_results` (já tem
`played_at` + índice `[user_id, played_at]`), o `RankingController` e a view de ranking.

Três camadas:

1. **Dados** — `GameResult.leaderboard(window:, limit:)`: agrega `SUM(score)` por usuário,
   filtrando por uma **janela de tempo** (`Range` ou `nil` = tudo). O fuso do app passa a ser
   `America/Sao_Paulo` (a janela semanal usa `Time.current.beginning_of_week`).
2. **Períodos + apresentação** — PORO `Quiz::Leaderboard` com um **registro de períodos**
   (`PERIODS`): cada período é `(key, label, window→Range|nil)`. Adicionar mensal/geral = +1
   linha. O PORO transforma as linhas agregadas em `Entry` uniformes (com email **mascarado**),
   prontas para a view.
3. **UI/fluxo** — `RankingController#index` escolhe o período (`params[:period]`, default = 1º
   habilitado) e monta as entries. A view renderiza um **toggle automático** (só quando há >1
   período) + a lista. O nickname-uma-vez ajusta a home e o `start`.

```mermaid
graph TD
    A[GET /ranking?period=weekly] --> B[RankingController#index]
    B --> C[Quiz::Leaderboard.for(:weekly)]
    C --> D[período.window(now) → Range]
    D --> E[GameResult.leaderboard(window:)]
    E -.SUM score por usuário.-> F[(game_results ⋈ users)]
    C --> G[Entries: rank, nickname, email mascarado, total, plays]
    G --> H[ranking/index + _ranking_list + toggle automático]
```

---

## Code Reuse Analysis

### Existing Components to Leverage

| Component | Location | How to Use |
|-----------|----------|------------|
| `GameResult` (+ `played_at`, índice `[user_id, played_at]`) | `app/models/game_result.rb` | Adicionar `leaderboard(window:)` agregado |
| Padrão PORO `Quiz::` | `app/models/quiz/energy.rb` | Replicar em `Quiz::Leaderboard` (registro + métodos puros) |
| `RankingController#index` | `app/controllers/ranking_controller.rb` | Selecionar período e montar entries |
| `ranking/index.html.erb` | `app/views/ranking/index.html.erb` | Toggle automático + parcial de lista; CTA de convidado reaproveitado |
| Fluxo de nickname (1º login) | `nicknames_controller.rb`, `nicknames/new.html.erb` | Reaproveitar `new`/`create` como edição explícita |
| Home + `#start` | `matches/_home.html.erb`, `matches_controller.rb` | Remover campo de apelido p/ logado; sessão p/ convidado |

### Integration Points

| System | Integration Method |
|--------|--------------------|
| `game_results ⋈ users` (PostgreSQL) | `GROUP BY users.id` + `SUM(score)` filtrado por `played_at` (janela) |
| Fuso horário | `config.time_zone = "America/Sao_Paulo"` (armazenamento segue UTC) |
| Roteamento | `params[:period]` em `GET /ranking`; nova rota de edição de nickname |
| Sessão (convidado) | `session[:nickname]` (apelido persistido entre partidas) |

---

## Components

### `GameResult` (extensão — camada de dados)

- **Purpose**: Agregação por usuário dentro de uma janela de tempo (ou tudo).
- **Location**: `app/models/game_result.rb`
- **Interface**:
  ```ruby
  # window: Range de played_at (ex.: inicio_semana..), ou nil para "todo o período".
  def self.leaderboard(window: nil, limit: 50)
    rel = joins(:user)
    rel = rel.where(played_at: window) if window
    rel.group("users.id, users.nickname, users.email")
       .select("users.id AS user_id, users.nickname AS nickname, users.email AS email,
                SUM(score) AS total_score, COUNT(*) AS plays")
       .order(Arel.sql("SUM(score) DESC, users.id ASC"))
       .limit(limit)
  end
  ```
- **Reuses**: índice `[user_id, played_at]`; `belongs_to :user`.
- **Requirement**: RANKW-02, RANKW-03, RANKW-04, RANKW-05.

### `Quiz::Leaderboard` (PORO — períodos + apresentação)

- **Purpose**: Registrar os períodos e devolver `Entry` uniformes (com email mascarado).
- **Location**: `app/models/quiz/leaderboard.rb`
- **Estruturas**:
  ```ruby
  Entry  = Struct.new(:rank, :user_id, :nickname, :masked_email, :value, :detail, keyword_init: true)
  Period = Struct.new(:key, :label, :window, keyword_init: true)  # window: ->(now) { Range | nil }

  # Registro: ordem = ordem do toggle. Ligar mensal/geral = descomentar/+1 linha.
  PERIODS = [
    Period.new(key: :weekly,  label: "Semanal", window: ->(now) { now.beginning_of_week.. }),
    # Futuro (1 linha cada):
    # Period.new(key: :monthly, label: "Mensal", window: ->(now) { now.beginning_of_month.. }),
    # Period.new(key: :all_time, label: "Geral",  window: ->(_)  { nil }),
  ].freeze
  ```
- **Interface** (`module_function`, puro):
  - `Quiz::Leaderboard.periods -> [Period]` (para o toggle)
  - `Quiz::Leaderboard.find_period(key) -> Period` (default: 1º; chave inválida cai no default)
  - `Quiz::Leaderboard.for(period_key, now: Time.current, limit: 50) -> [Entry]`
    - chama `GameResult.leaderboard(window: período.window.call(now), limit:)`
    - `value = total_score`; `detail = "#{plays} partida(s)"`; `nickname` ou "Anônimo"
    - `masked_email = mask_email(row.email)`; `rank` sequencial 1..N
  - `Quiz::Leaderboard.mask_email(email) -> String` — `"#{local[0]}***@#{domain}"`
    (vazio → ""; local de 1 char ainda oculta)
- **Dependencies**: `GameResult`.
- **Reuses**: padrão `Quiz::Energy`.
- **Requirement**: RANKW-06, RANKW-08, RANKW-09.

> O destaque "(você)" **não** entra no `Entry` (depende de `current_user`, que é da view).
> A view marca `is_me = user_signed_in? && entry.user_id == current_user.id`.

### `RankingController#index`

- **Location**: `app/controllers/ranking_controller.rb`
- **Lógica**:
  ```ruby
  @periods = Quiz::Leaderboard.periods
  @period  = Quiz::Leaderboard.find_period(params[:period])
  @entries = Quiz::Leaderboard.for(@period.key)
  ```
- **Requirement**: RANKW-01, RANKW-07.

### Views (UI do ranking)

- **Toggle automático** — `ranking/index.html.erb`: itera `@periods`; renderiza a barra de abas
  **só quando `@periods.size > 1`**, cada aba linkando `ranking_path(period: p.key)`, com a ativa
  destacada. Com 1 período (estado atual), exibe direto, sem barra. (RANKW-07)
- **Lista** — parcial `ranking/_ranking_list.html.erb` itera `@entries`: medalha/posição
  (`entry.rank`), `entry.nickname`, `entry.masked_email`, `entry.value`, `entry.detail`, e o
  destaque "(você)". (RANKW-08, RANKW-10)
- **Estado vazio** — `@entries.empty?` → "Nenhum resultado nesta semana ainda". (RANKW-11)
- **CTA convidado** — inalterado. (RANKW-11)

### Nickname digitado uma única vez (`NICK`)

- **Rotas** — além de `new_nickname`/`nickname` (já existem), o fluxo de edição reaproveita
  `nicknames#new`/`create` (o `create` já faz `update`). Acesso via link explícito "Mudar
  apelido". (Opcional: rota semântica `get /nickname/edit` apontando para a mesma action.)
- **Home (`matches/_home.html.erb`)**:
  - **Logado:** remover o campo de apelido. Mostrar "Olá, **{nickname}**!", botão "Jogar agora"
    e link **"Mudar apelido"** → `new_nickname_path`. (NICK-01, NICK-02)
  - **Convidado com `session[:nickname]`:** sem campo; "Jogando como **{apelido}**" + botão +
    link **"Trocar apelido"** (`root_path(edit_nick: 1)` reabre o campo). (NICK-03, NICK-04)
  - **Convidado sem apelido (ou `edit_nick`):** mostra o campo uma vez. (NICK-03)
- **`MatchesController#start`** — resolve o apelido sem re-solicitar:
  ```ruby
  nick = if user_signed_in?
           current_user.nickname
         else
           session[:nickname] = params[:nickname].presence || session[:nickname]
           session[:nickname]
         end
  @match = Quiz::MatchState.start(nickname: nick)
  ```
  (NICK-01, NICK-03)
- **Requirement**: NICK-01..04.

---

## Data Models

**Sem migration.** Reaproveita as colunas existentes:

| Coluna (`game_results`) | Uso |
|--------|-----|
| `played_at` (datetime, índice c/ `user_id`) | Filtro pela janela do período |
| `score` (integer) | `SUM(score)` por usuário |
| `user_id` (fk) | `GROUP BY`; junção com `users` |
| `users.nickname`, `users.email` | Exibição (email → mascarado) |

### Recorte do período (semanal)

```
now           = Time.current               # fuso do app = America/Sao_Paulo
inicio_semana = now.beginning_of_week      # segunda 00h (Brasília)
window        = inicio_semana..            # played_at >= inicio_semana
```

`config.active_record.default_timezone` permanece `:utc` (armazenamento em UTC). Só a
leitura/cálculo de fronteira passa a Brasília via `config.time_zone`.

---

## Error Handling Strategy

| Error Scenario | Handling | User Impact |
|----------------|----------|-------------|
| Período sem partidas | `leaderboard` retorna vazio → estado vazio na view | "Nenhum resultado nesta semana ainda" |
| Empate no total | Ordem `SUM(score) DESC, user_id ASC` (determinística) | Ordem estável, sem erro |
| `params[:period]` inválido | `find_period` cai no 1º período | Mostra o Semanal |
| Email ausente/local curto | `mask_email` retorna "" ou oculta mesmo com 1 char | Nunca vaza o email |
| Convidado sem login | Sem `current_user`; nenhuma linha marcada "você" | Vê a lista + CTA login |
| Convidado limpa a sessão | `session[:nickname]` some → pede apelido de novo | Aceito (limitação conhecida) |

---

## Tech Decisions (only non-obvious ones)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Ranking por **período** | Registro `PERIODS` (key/label/window) | Mensal/geral = +1 linha; toggle automático; janela `nil` = geral agregado |
| Agregação única | `SUM(score)` por usuário, filtrada por janela | Mesmo código serve semanal, mensal e geral |
| Substituir o geral atual (por partida) | Só **Semanal** habilitado agora | Decisão do dono ("inicialmente só semanal"); geral por partida é aposentado em favor do modelo por período |
| Fronteira da semana | `beginning_of_week` + `config.time_zone` | Reset segunda 00h Brasília **sem job**; fuso num lugar só |
| Email no público | **Mascarado** (`d***@dominio`) | Ranking é público; email completo é PII — não expor |
| Nickname | Logado = cadastro; convidado = `session[:nickname]` | Pede uma vez; trocar é ação explícita |
| Tie-break | `user_id` como desempate | MVP estável; "quem chegou primeiro" fica deferido |

---

## Risks & Notes

- **Fuso afeta o app todo:** mudar `config.time_zone` altera exibição/`beginning_of_week`, mas
  **não** altera diferenças de instante. A energia (`now - updated_at`, `RECHARGE_INTERVAL`) é
  imune; os testes de energia usam `Time.utc(...)`. T1 valida rodando a suíte de energia. (RANKW-12)
- **Regressão do ranking geral atual:** o teste `test/integration/ranking_test.rb` cobre o
  comportamento **por partida** que está sendo substituído — será **atualizado** em T3 para o
  modelo por período (a asserção de ordem 400 > 200 continua válida pois joão soma 400 e maria
  200, mas a semântica passa a ser por usuário).
- **Índice:** `[user_id, played_at]` cobre o agrupamento por usuário. Índice só em `played_at`
  pode acelerar o range global no futuro — **deferido** (escala pequena).
- **`played_at` na criação:** `MatchesController` cria `GameResult` sem `played_at` (usa default
  `CURRENT_TIMESTAMP`). Continua válido.
- **Nickname só para logado pontua:** convidado não gera `GameResult`, então não aparece no
  ranking — o `session[:nickname]` é só cosmético durante a partida.

---

## Resolved Questions (2026-06-14)

1. **Métrica:** soma dos pontos do período (`SUM(score)`).
2. **Períodos:** só **Semanal** habilitado agora; mensal/geral ficam prontos no registro.
3. **UI:** toggle **automático** (aparece com >1 período); default = 1º período.
4. **Fuso/Reset:** `America/Sao_Paulo`, semana reseta segunda 00h.
5. **Email:** exibido **mascarado** (`d***@dominio`), nunca completo.
6. **Nickname:** digitado uma única vez; trocar é ação explícita.

**Status:** Approved.

# Mecânica de Energia — Tasks

**Design:** `.specs/features/energia/design.md`
**Spec:** `.specs/features/energia/spec.md`
**Testing:** `.specs/codebase/TESTING.md` (Minitest)
**Status:** Ready
**Baseline:** 43 testes passando

---

## Execution Plan

### Phase 1: Fundação (Sequential)

```
T1 (Quiz::Energy) → T2 (User + migration) → T3 (gate no controller)
```

### Phase 2: UI (Parallel após Phase 1)

```
T2 ──→ T4 [P] (indicador ⚡ header+home)
T3 ──→ (T4 não depende de T3; depende de T2)
```

### Phase 3: System Test (Sequential)

```
T3, T4 → T5 (system test do fluxo)
```

---

## Task Breakdown

### T1: `Quiz::Energy` — PORO de config + regeneração

**What:** Criar o PORO puro `Quiz::Energy` que centraliza a configuração (teto, intervalo de recarga, limite de convidado) e o cálculo de regeneração por intervalo. Sem ActiveRecord, sem BD — recebe valores, devolve valores.
**Where:**
- `app/models/quiz/energy.rb`
- `test/models/quiz/energy_test.rb`
**Depends on:** None
**Reuses:** Padrão PORO de `app/models/quiz/match_state.rb` (config por constantes no topo)
**Requirement:** ENERGY-06, ENERGY-07, ENERGY-08

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Constantes de config no topo (ponto único): `MAX = 5`, `RECHARGE_INTERVAL = 2.hours`, `GUEST_MAX = 3`
- [ ] `Quiz::Energy.current(stored:, updated_at:, now: Time.current)` → energia regenerada virtual, limitada a `MAX`
- [ ] `Quiz::Energy.settle(stored:, updated_at:, now:)` → `[energy, updated_at]` acertados (aplica regen, avança o relógio preservando o resto; `now` quando atinge o teto)
- [ ] `Quiz::Energy.next_recharge_at(stored:, updated_at:, now:)` → `Time` da próxima recarga, ou `nil` se cheia
- [ ] `updated_at` nulo é tratado como energia cheia (`current` retorna `MAX`)
- [ ] Testes unitários cobrem:
  - cheia (`stored == MAX`) → `current == MAX`, `next_recharge_at == nil`
  - 1 intervalo decorrido → `current == stored + 1`
  - N intervalos decorridos → `current == min(MAX, stored + N)` (nunca passa do teto)
  - menos de 1 intervalo → `current == stored` (sem fração)
  - `updated_at` nulo → `current == MAX`
  - `settle` preserva o "resto" (ex.: 2.5 intervalos → +2 e relógio avança 2 intervalos)
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 43 + ~6 = **~49 testes passam**

**Tests:** unit · **Gate:** quick
**Commit:** `feat(energia): Quiz::Energy — config e regeneração por intervalo`

---

### T2: Migration + métodos de energia no `User`

**What:** Adicionar colunas `energy` e `energy_updated_at` à tabela `users` e os métodos de energia no model `User`, delegando o cálculo ao `Quiz::Energy`. Inclui o débito atômico via `with_lock`.
**Where:**
- `db/migrate/*_add_energy_to_users.rb`
- `app/models/user.rb`
- `test/models/user_test.rb` (estender)
**Depends on:** T1
**Reuses:** `Quiz::Energy` (T1); AR `with_lock`
**Requirement:** ENERGY-01, ENERGY-02, ENERGY-03, ENERGY-06

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Migration: `add_column :users, :energy, :integer, null: false, default: Quiz::Energy::MAX`
- [ ] Migration: `add_column :users, :energy_updated_at, :datetime, null: true`
- [ ] `bin/rails db:migrate` executa sem erro
- [ ] `User#current_energy(now = Time.current)` → leitura virtual via `Quiz::Energy.current` (não persiste)
- [ ] `User#next_recharge_at(now = Time.current)` → delega a `Quiz::Energy.next_recharge_at`
- [ ] `User#unlimited_energy?` → retorna `false` (gancho do M3)
- [ ] `User#debit_energy!` → dentro de `with_lock`: `settle` → retorna `false` se `< 1` → decrementa 1 → ajusta `energy_updated_at` (se vinha do teto, `= now`) → `update!`; retorna `true` no sucesso
- [ ] Testes unitários cobrem:
  - `debit_energy!` em saldo cheio → decrementa para 4, retorna `true`
  - `debit_energy!` com saldo 0 (via setup) → retorna `false`, saldo continua 0
  - `unlimited_energy?` → `false`
  - `current_energy` regenera após avançar o relógio (`travel_to`)
  - `current_energy` com `energy_updated_at` nulo → `MAX`
  - dois `debit_energy!` seguidos a partir de 1 → segundo retorna `false` (não fica negativo)
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: ~49 + ~6 = **~55 testes passam**

**Tests:** unit · **Gate:** quick
**Commit:** `feat(energia): colunas e métodos de energia no User (débito atômico)`

---

### T3: Gate de energia no `MatchesController#start`

**What:** Inserir o portão de energia no início da partida: logado debita (bloqueia em `:no_energy`); convidado conta na sessão (bloqueia em `:no_energy_guest` ao atingir `GUEST_MAX`). Criar os parciais das duas telas de bloqueio. Extrair `before_action :set_guest_flag` (remove duplicação de `@is_guest`).
**Where:**
- `app/controllers/matches_controller.rb` (modificar)
- `app/views/matches/_no_energy.html.erb` (novo)
- `app/views/matches/_no_energy_guest.html.erb` (novo)
- `app/views/matches/show.html.erb` (adicionar branches de `@screen`)
- `test/integration/energy_gate_test.rb` (novo)
**Depends on:** T2
**Reuses:** estrutura de `@screen`/`render :show`; `ranking_path`; `torcedor_maluco.css`; helper OAuth de login (parcial de `_home`/`_result`)
**Requirement:** ENERGY-01, ENERGY-04, ENERGY-05, ENERGY-09, ENERGY-10

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `#start` — logado: `unless current_user.unlimited_energy? || current_user.debit_energy!` → `@screen = :no_energy; return render :show`
- [ ] `#start` — convidado: `if session[:guest_plays].to_i >= Quiz::Energy::GUEST_MAX` → `@screen = :no_energy_guest; return render :show`; senão incrementa `session[:guest_plays]`
- [ ] `#start` — sucesso: segue o fluxo atual (`Quiz::MatchState.start`)
- [ ] `before_action :set_guest_flag` define `@is_guest = !user_signed_in?` (substitui as duas atribuições duplicadas em `#show` e `#next_question`)
- [ ] `show.html.erb` renderiza `_no_energy` quando `@screen == :no_energy` e `_no_energy_guest` quando `:no_energy_guest`
- [ ] `_no_energy.html.erb`: contagem até `current_user.next_recharge_at` + placeholder "Em breve: jogadas ilimitadas para assinantes" + botão "Ver ranking" (`ranking_path`)
- [ ] `_no_energy_guest.html.erb`: "Faça login com Google para jogar mais" + botão OAuth
- [ ] Testes de integração:
  - logado com energia → `POST /match/start` inicia partida e debita 1 (`current_energy` cai)
  - logado com energia 0 → `POST /match/start` renderiza tela `:no_energy`, não cria partida na sessão
  - convidado abaixo do limite → joga e incrementa `session[:guest_plays]`
  - convidado no limite (`GUEST_MAX`) → `POST /match/start` renderiza `:no_energy_guest`
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: ~55 + ~4 = **~59 testes passam**

**Tests:** integration · **Gate:** full
**Commit:** `feat(energia): gate de energia no início da partida (logado + convidado)`

---

### T4: Indicador de energia no header + home [P]

**What:** Exibir o saldo de energia (`⚡ x/5`) e o tempo até a próxima recarga para usuários logados, no header do quiz e em destaque na home. "∞" quando `unlimited_energy?`.
**Where:**
- `app/views/matches/_energy.html.erb` (novo parcial)
- `app/views/layouts/matches.html.erb` (incluir no header)
- `app/views/matches/_home.html.erb` (incluir na home)
- `app/assets/stylesheets/torcedor_maluco.css` (estilo do indicador)
**Depends on:** T2
**Reuses:** `current_user.current_energy`, `#next_recharge_at`, `#unlimited_energy?`; CSS hi-fi existente
**Requirement:** ENERGY-11, ENERGY-12

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Parcial `_energy.html.erb`: mostra `⚡ {current_energy}/5`; se não cheia, "próxima em ~Xh"; se `unlimited_energy?`, "⚡ ∞"
- [ ] Renderizado no header de `layouts/matches.html.erb` apenas quando `user_signed_in?`
- [ ] Renderizado em destaque em `_home.html.erb` quando `user_signed_in?`
- [ ] Estilo coerente com `torcedor_maluco.css` (mobile-first)
- [ ] App sobe sem erro de template; `bin/rails test` sem regressão
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: ~59 testes passam (view estática — sem novos testes unitários)

**Tests:** none · **Gate:** build
**Commit:** `feat(energia): indicador de energia no header e na home`

---

### T5: System test — exaustão de energia e limite de convidado

**What:** Teste de sistema (Capybara) cobrindo: usuário logado esgota a energia e vê a tela "Sem energia" com a contagem e o botão "Ver ranking"; e convidado atinge o limite de sessão e vê o CTA de login.
**Where:** `test/system/energy_flow_test.rb`
**Depends on:** T3, T4
**Reuses:** Capybara; OmniAuth test mode; `travel_to`/manipulação de saldo para forçar o estado
**Requirement:** ENERGY-04, ENERGY-05, ENERGY-10, ENERGY-11

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Cenário 1 — Logado sem energia:
  - logar (mock OAuth) → forçar `energy = 0` → visitar home → ver indicador `⚡ 0/5` → tentar jogar → ver tela "Sem energia" com contagem e botão "Ver ranking"
- [ ] Cenário 2 — Convidado no limite:
  - sem login → jogar `GUEST_MAX` (3) partidas → na tentativa seguinte ver "Faça login com Google para jogar mais"
- [ ] Gate passa: `bin/rails test:all`
- [ ] Test count: ~59 + ~2 system tests = **~61 testes passam**

**Tests:** system · **Gate:** full
**Commit:** `test(energia): system tests — sem energia (logado) e limite de convidado`

---

## Parallel Execution Map

```
Phase 1 (Sequential):
  T1 → T2 → T3

Phase 2 (Parallel — T4 depende só de T2):
  T2 ──→ T4 [P]

Phase 3 (Sequential — system test não é parallel-safe):
  T3, T4 → T5
```

> Nota: T4 pode rodar em paralelo com T3 (ambos dependem só de T2). Com um único executor, a ordem natural é T1→T2→T3→T4→T5.

---

## Validação Pré-Aprovação

### Check 1 — Granularidade

| Task | Escopo | Status |
|------|--------|--------|
| T1 | 1 PORO (Quiz::Energy) + testes unit | ✅ coeso |
| T2 | 1 migration + métodos no User | ✅ |
| T3 | 1 controller + 2 parciais de bloqueio (slice "gate") | ✅ coeso |
| T4 | 1 parcial + 2 inclusões + CSS (mesmo concern: indicador) | ✅ |
| T5 | 1 system test (2 cenários) | ✅ |

### Check 2 — Diagrama × Dependências

| Task | Depends on (corpo) | Diagrama mostra | Status |
|------|--------------------|-----------------|--------|
| T1 | None | — | ✅ |
| T2 | T1 | T1→T2 | ✅ |
| T3 | T2 | T2→T3 | ✅ |
| T4 | T2 | T2→T4 [P] | ✅ |
| T5 | T3, T4 | T3,T4→T5 | ✅ |

### Check 3 — Co-localização de testes (matriz TESTING.md)

| Task | Camada criada/modificada | Matriz exige | Task diz | Status |
|------|--------------------------|--------------|----------|--------|
| T1 | Lógica pura (regeneração/pontuação-like) | unit | unit | ✅ |
| T2 | Model (`User`) | unit | unit | ✅ |
| T3 | Controller (fluxo de partida) | integration | integration | ✅ |
| T4 | Views/parciais estáticas | none | none | ✅ |
| T5 | Tela (jogar no navegador) | system | system | ✅ |

---

## Pergunta antes de Executar (MCPs e Skills)

- **Todas as tasks:** apenas ferramentas nativas de edição + Bash (`bin/rails`); sem MCP externo.
- **T2:** `rails generate migration` + `db:migrate` via Bash.
- **T5:** `bin/rails test:all` via Bash; OmniAuth test mode mockado no próprio teste.

Commits atômicos por tarefa, localmente (como no M1/M2).

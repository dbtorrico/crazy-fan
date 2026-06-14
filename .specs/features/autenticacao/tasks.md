# Autenticação — Tasks

**Design:** `.specs/features/autenticacao/design.md`
**Testing:** `.specs/codebase/TESTING.md` (Minitest)
**Status:** ✅ DONE (2026-06-13)

---

## Execution Plan

### Phase 1: Fundação (Sequential)

```
T1 → T2 → T3 → T4
```

### Phase 2: Componentes (Parallel após T4)

```
T4 ──┬→ T5 [P]
     ├→ T6 [P]
     ├→ T7 [P]
     ├→ T8 [P]
     └→ T9 [P]
```

### Phase 3: System Test (Sequential)

```
T5, T6, T7, T8, T9 → T10
```

---

## Task Breakdown

### T1: Adicionar gems Devise + OmniAuth ao Gemfile

**What:** Adicionar `devise`, `omniauth-google-oauth2` e `omniauth-rails_csrf_protection` ao `Gemfile` e executar `bundle install`.
**Where:** `Gemfile`
**Depends on:** None
**Reuses:** Padrão Gemfile existente
**Requirement:** (fundação de todos os AUTH-*)

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `gem "devise"` presente no Gemfile
- [ ] `gem "omniauth-google-oauth2"` presente no Gemfile
- [ ] `gem "omniauth-rails_csrf_protection"` presente no Gemfile
- [ ] `bundle install` executa sem erro
- [ ] `bin/rails test` ainda passa (17 testes, sem regressão)

**Tests:** none · **Gate:** build
**Commit:** `chore(auth): adiciona gems Devise e OmniAuth ao Gemfile`

---

### T2: User model + Devise install (OAuth-only, sem senha)

**What:** Instalar Devise, gerar model `User` configurado apenas para OAuth (sem `database_authenticatable`, sem senha), com campos `provider`, `uid`, `email`, `nickname`, `nickname_set`, `avatar_url` e método de classe `User.from_omniauth(auth)`.
**Where:**
- `Gemfile` (sem mudança)
- `config/initializers/devise.rb` (gerado)
- `app/models/user.rb`
- `db/migrate/*_devise_create_users.rb`
**Depends on:** T1
**Reuses:** `rails generate devise:install`, `rails generate devise User`
**Requirement:** AUTH-04, AUTH-05, AUTH-08, AUTH-09, AUTH-10

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `rails generate devise:install` executado; `config/initializers/devise.rb` gerado
- [ ] `rails generate devise User` executado; migration gerada
- [ ] Migration **não contém** colunas de senha (`encrypted_password`, `reset_password_*`, `confirmation_*`) — removidas manualmente
- [ ] Migration **contém** as colunas: `provider (string, not null)`, `uid (string, not null)`, `email (string, not null)`, `nickname (string, limit: 18)`, `nickname_set (boolean, default: false, not null)`, `avatar_url (string)`
- [ ] Índices únicos: `[provider, uid]`, `email`, `nickname`
- [ ] Devise modules no model: `:omniauthable, :rememberable, :trackable` (sem `:database_authenticatable`, `:registerable`, `:recoverable`, `:confirmable`, `:lockable`)
- [ ] `User.from_omniauth(auth)` implementado: `find_or_create_by(provider:, uid:)` preenchendo `email` e `avatar_url` do `auth.info`
- [ ] Validação: nickname — presença (se `nickname_set`), tamanho (3–18), formato (`/\A[\w\-]+\z/`), unicidade
- [ ] `bin/rails db:migrate` executa sem erro
- [ ] Testes unitários cobrem:
  - `from_omniauth` encontra usuário existente (não duplica)
  - `from_omniauth` cria novo usuário
  - Nickname válido passa; inválido (tamanho, charset) falha
  - `nickname_set` começa como `false`
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 17 + 5 = **22 testes passam**

**Tests:** unit · **Gate:** quick
**Commit:** `feat(auth): User model OAuth-only com Devise (sem senha)`

---

### T3: GameResult model + migration

**What:** Model `GameResult` com `belongs_to :user`, campos `score`, `correct_count`, `questions_count`, `played_at` e validações de presença.
**Where:**
- `app/models/game_result.rb`
- `db/migrate/*_create_game_results.rb`
- `test/models/game_result_test.rb`
**Depends on:** T2
**Reuses:** `rails generate model`
**Requirement:** AUTH-11

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Migration cria tabela `game_results` com `user_id (FK, not null)`, `score (integer, not null)`, `correct_count (integer, not null)`, `questions_count (integer, not null, default: 5)`, `played_at (datetime, not null)`
- [ ] Índice em `[user_id, played_at]`
- [ ] Model: `belongs_to :user`; validações de presença em `score`, `correct_count`, `questions_count`
- [ ] `bin/rails db:migrate` executa sem erro
- [ ] Testes unitários: pertence a user, rejeita sem score, rejeita sem correct_count
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 22 + 3 = **25 testes passam**

**Tests:** unit · **Gate:** quick
**Commit:** `feat(auth): model GameResult com FK para User`

---

### T4: Configuração OmniAuth Google + rotas Devise

**What:** Configurar OmniAuth Google OAuth2 no initializer do Devise (via ENV vars), adicionar rotas `devise_for`, rota de logout, rotas de nickname e ranking ao `config/routes.rb`.
**Where:**
- `config/initializers/devise.rb` (modificar)
- `config/routes.rb` (modificar)
- `.env.example` (novo — documentar variáveis obrigatórias)
**Depends on:** T2
**Reuses:** rotas existentes em `config/routes.rb`
**Requirement:** AUTH-04, AUTH-07

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `config/initializers/devise.rb` contém:
  ```ruby
  config.omniauth :google_oauth2,
    ENV["GOOGLE_CLIENT_ID"],
    ENV["GOOGLE_CLIENT_SECRET"],
    scope: "email,profile"
  ```
- [ ] `config/routes.rb` contém:
  ```ruby
  devise_for :users,
    controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
    skip: [:sessions, :passwords, :registrations, :confirmations]
  devise_scope :user do
    delete "/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end
  get  "/nickname/new", to: "nicknames#new",    as: :new_nickname
  post "/nickname",     to: "nicknames#create",  as: :nickname
  get  "/ranking",      to: "ranking#index",     as: :ranking
  ```
- [ ] `.env.example` criado com `GOOGLE_CLIENT_ID=` e `GOOGLE_CLIENT_SECRET=`
- [ ] `bin/rails routes` lista as novas rotas sem erro
- [ ] App sobe (`bin/rails server`) sem erro de configuração
- [ ] Gate passa: `bin/rails test` (25 testes, sem regressão)

**Tests:** none · **Gate:** build
**Commit:** `feat(auth): configura OmniAuth Google e rotas Devise`

---

### T5: Users::OmniauthCallbacksController [P]

**What:** Controller que recebe o callback OAuth do Google, chama `User.from_omniauth`, faz `sign_in` e decide redirect (novo usuário → `new_nickname_path`; existente → `root_path`; falha → `root_path` com alerta).
**Where:**
- `app/controllers/users/omniauth_callbacks_controller.rb`
- `test/integration/omniauth_callbacks_test.rb`
**Depends on:** T2, T4
**Reuses:** `User.from_omniauth`; padrão Devise `sign_in_and_redirect`
**Requirement:** AUTH-04, AUTH-05, AUTH-06

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Controller herda de `Devise::OmniauthCallbacksController`
- [ ] Action `#google_oauth2` implementada: chama `User.from_omniauth`, faz `sign_in`, verifica `nickname_set?` para escolher redirect
- [ ] Action `#failure` redireciona para `root_path` com `alert:`
- [ ] Testes de integração usam `OmniAuth.config.test_mode = true` + `OmniAuth::AuthHash` mockado:
  - Novo usuário (sem nickname) → `sign_in` + redirect para `new_nickname_path`
  - Usuário existente (com nickname) → `sign_in` + redirect para `root_path`
  - OAuth falhou → redirect para `root_path` com flash `alert`
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 25 + 3 = **28 testes passam**

**Tests:** integration · **Gate:** full
**Commit:** `feat(auth): OmniauthCallbacksController — login via Google OAuth`

---

### T6: NicknamesController [P]

**What:** Controller que exibe o form de nickname (pré-preenchido com `first_name` do Google) e salva o nickname; requer login (`authenticate_user!`).
**Where:**
- `app/controllers/nicknames_controller.rb`
- `app/views/nicknames/new.html.erb`
- `test/integration/nicknames_test.rb`
**Depends on:** T2, T4
**Reuses:** layout `matches`; validações já em `User` (T2)
**Requirement:** AUTH-08, AUTH-09, AUTH-10

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `NicknamesController` com `before_action :authenticate_user!`, actions `#new` e `#create`
- [ ] `#new` expõe `@suggested_nickname = current_user.email.split("@").first.slice(0, 18)`
- [ ] `#create` chama `current_user.update(nickname:, nickname_set: true)`; em sucesso redireciona para `root_path`; em falha re-renderiza `new` com erros
- [ ] View `nicknames/new.html.erb` usa layout `matches`; campo `nickname` pré-preenchido; exibe erros de validação
- [ ] Sugestão de nickname com sufixo numérico quando já existe: `nickname + "_" + rand(10..99).to_s`
- [ ] Testes de integração:
  - GET `/nickname/new` sem login → redirect para root (Devise)
  - GET `/nickname/new` logado → exibe form com sugestão
  - POST `/nickname` com nickname válido e único → salva, redireciona root
  - POST `/nickname` com nickname inválido → re-renderiza com erro
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 28 + 4 = **32 testes passam**

**Tests:** integration · **Gate:** full
**Commit:** `feat(auth): NicknamesController — escolha de nickname no primeiro login`

---

### T7: RankingController + view básica [P]

**What:** Controller que lista os melhores `GameResult` (top 50, score desc, inclui nickname do User), acessível por convidados e logados.
**Where:**
- `app/controllers/ranking_controller.rb`
- `app/views/ranking/index.html.erb`
- `test/integration/ranking_test.rb`
**Depends on:** T3, T4
**Reuses:** layout `matches`; `GameResult` (T3); `torcedor_maluco.css`
**Requirement:** AUTH-03

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `RankingController#index` carrega `GameResult.order(score: :desc).limit(50).includes(:user)`, expõe como `@results`
- [ ] View lista resultados: posição, nickname, score, data
- [ ] Para convidados: faixa no topo "Faça login com Google para entrar no ranking" com link para OAuth
- [ ] Para logados: highlight na linha do `current_user` (se presente no top 50)
- [ ] Acessível sem login (sem `authenticate_user!`)
- [ ] Testes de integração:
  - GET `/ranking` sem login → 200, exibe faixa de CTA
  - GET `/ranking` com resultados → lista ordenada por score desc
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 32 + 2 = **34 testes passam**

**Tests:** integration · **Gate:** full
**Commit:** `feat(auth): RankingController — lista básica de melhores resultados`

---

### T8: MatchesController — salvar GameResult ao terminar [P]

**What:** Modificar `MatchesController#next_question` para salvar `GameResult` quando a partida termina e o usuário está logado; passar `@is_guest` para a view.
**Where:**
- `app/controllers/matches_controller.rb` (modificar)
- `test/integration/game_result_saving_test.rb`
**Depends on:** T3, T4
**Reuses:** `Quiz::MatchState#finished?`, `#score`, `#correct_count`, `#total`; `GameResult.create!`
**Requirement:** AUTH-11, AUTH-12

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `MatchesController#next_question` salva `GameResult` quando `@match.finished? && user_signed_in?`
- [ ] `MatchesController#show` atribui `@is_guest = !user_signed_in?` antes de renderizar
- [ ] GameResult **não** é salvo quando convidado (`!user_signed_in?`)
- [ ] GameResult **não** é salvo quando partida não terminou (`!@match.finished?`)
- [ ] Testes de integração (usar session fixtures para simular partida completa):
  - Usuário logado termina partida → `GameResult.count` incrementa 1
  - Convidado termina partida → `GameResult.count` permanece 0
  - Partida não terminada → `GameResult.count` permanece 0
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 34 + 3 = **37 testes passam**

**Tests:** integration · **Gate:** full
**Commit:** `feat(auth): salva GameResult em MatchesController quando logado`

---

### T9: Views — mensagens de convidado/logado + botão de login [P]

**What:** Atualizar `matches/_result.html.erb`, `matches/_home.html.erb` e `app/views/layouts/matches.html.erb` com blocos condicionais `user_signed_in?` para CTAs de auth, mensagens e logout.
**Where:**
- `app/views/matches/_result.html.erb` (modificar)
- `app/views/matches/_home.html.erb` (modificar)
- `app/views/layouts/matches.html.erb` (modificar)
**Depends on:** T4
**Reuses:** CSS existente (`torcedor_maluco.css`); helpers Devise (`user_signed_in?`, `current_user`, `destroy_user_session_path`)
**Requirement:** AUTH-01, AUTH-02, AUTH-03, AUTH-12, AUTH-14

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] `_result.html.erb`:
  - Se convidado (`@is_guest`): aviso "Você jogou como convidado" + botão "Entrar no ranking com Google" → `POST /auth/google_oauth2`
  - Se logado: mensagem "✓ Resultado salvo no ranking!" + link para `/ranking`
- [ ] `_home.html.erb`:
  - Se convidado: link discreto "Login com Google" abaixo do botão "Jogar agora"
  - Se logado: saudação "Olá, [nickname]!" + link "Ver ranking"
- [ ] `layouts/matches.html.erb`:
  - Header: se logado, exibe nickname + botão "Sair" (`DELETE /logout`)
- [ ] App sobe sem erro de template; `bin/rails test` continua passando (sem regressão)
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 37 testes passam (views estáticas — sem novos testes de unidade)

**Tests:** none · **Gate:** build
**Commit:** `feat(auth): views — CTAs de login/logout e mensagens convidado vs logado`

---

### T10: System test — fluxo completo de autenticação

**What:** Teste de sistema (Capybara) cobrindo: login com Google (mock), tela de nickname, partida com resultado salvo no ranking; e fluxo paralelo de convidado vendo ranking mas não estando nele.
**Where:** `test/system/auth_flow_test.rb`
**Depends on:** T5, T6, T7, T8, T9
**Reuses:** Capybara; OmniAuth test mode; fixtures de questions/answers existentes
**Requirement:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-07, AUTH-08, AUTH-11, AUTH-12

**Tools:** MCP: NONE · Skill: NONE

**Done when:**
- [ ] Cenário 1 — Login + nickname + partida:
  - Visita home → clica "Login com Google" → mock OAuth retorna → tela de nickname → define nickname → joga partida completa → tela de resultado mostra "✓ Resultado salvo" → visita `/ranking` → vê seu resultado na lista
- [ ] Cenário 2 — Convidado:
  - Visita home sem login → joga partida → tela de resultado mostra "jogou como convidado" + botão de login → visita `/ranking` → vê faixa "faça login para entrar"
- [ ] Cenário 3 — Logout:
  - Usuário logado clica "Sair" → deslogado → home mostra botão de login novamente
- [ ] Gate passa: `bin/rails test:all`
- [ ] Test count: 37 + 3 system tests = **40 testes passam**

**Tests:** system · **Gate:** full
**Commit:** `test(auth): system tests — login, nickname, ranking e fluxo de convidado`

---

## Parallel Execution Map

```
Phase 1 (Sequential):
  T1 → T2 → T3 → T4

Phase 2 (Parallel — todos dependem de T4; T7 e T8 também de T3):
  T4 ──┬→ T5 [P]
       ├→ T6 [P]
       ├→ T7 [P]   (também depende de T3)
       ├→ T8 [P]   (também depende de T3)
       └→ T9 [P]

Phase 3 (Sequential — system test não é parallel-safe):
  T5, T6, T7, T8, T9 → T10
```

---

## Validação Pré-Aprovação

### Check 1 — Granularidade

| Task | Escopo | Status |
|------|--------|--------|
| T1 | 1 Gemfile + bundle install | ✅ coeso |
| T2 | 1 model + Devise install | ✅ |
| T3 | 1 model (GameResult) | ✅ |
| T4 | 1 initializer + rotas | ✅ |
| T5 | 1 controller (callbacks) | ✅ |
| T6 | 1 controller + 1 view (nicknames) | ✅ |
| T7 | 1 controller + 1 view (ranking) | ✅ |
| T8 | 1 controller modificado (matches) | ✅ |
| T9 | 3 views modificadas (mesmo concern: CTAs de auth) | ✅ coeso |
| T10 | 1 system test (3 cenários) | ✅ |

### Check 2 — Diagrama × Dependências

| Task | Depends on (corpo) | Diagrama mostra | Status |
|------|--------------------|-----------------|--------|
| T1 | None | — | ✅ |
| T2 | T1 | T1→T2 | ✅ |
| T3 | T2 | T2→T3 | ✅ |
| T4 | T2 | T2→...→T4 (via T3) | ✅ |
| T5 | T2, T4 | T4→T5 (T2 já concluída em Phase 1) | ✅ |
| T6 | T2, T4 | T4→T6 | ✅ |
| T7 | T3, T4 | T4→T7 (T3 concluída em Phase 1) | ✅ |
| T8 | T3, T4 | T4→T8 (T3 concluída em Phase 1) | ✅ |
| T9 | T4 | T4→T9 | ✅ |
| T10 | T5,T6,T7,T8,T9 | todos→T10 | ✅ |

Tarefas `[P]` (T5–T9) não dependem entre si. ✅

### Check 3 — Co-localização de testes (matriz TESTING.md)

| Task | Camada criada/modificada | Matriz exige | Task diz | Status |
|------|--------------------------|--------------|----------|--------|
| T1 | Gemfile | none | none | ✅ |
| T2 | Model (`User`) | unit | unit | ✅ |
| T3 | Model (`GameResult`) | model | unit | ✅ |
| T4 | Initializer + rotas | none | none | ✅ |
| T5 | Controller (callback) | integration | integration | ✅ |
| T6 | Controller + view | integration | integration | ✅ |
| T7 | Controller + view | integration | integration | ✅ |
| T8 | Controller (modificado) | integration | integration | ✅ |
| T9 | Views estáticas | none | none | ✅ |
| T10 | System test | system | system | ✅ |

---

## Pergunta antes de Executar (MCPs e Skills)

Ferramentas propostas para cada fase:

- **Todas as tasks:** apenas ferramentas nativas de edição de arquivos (sem MCP externo)
- **T2 (Devise install):** `rails generate` via Bash
- **T10 (system test):** `bin/rails test:all` via Bash; OmniAuth test mode mockado no próprio teste

Sem necessidade de MCP `github` para commits atômicos nesta feature (commits feitos localmente como no M1).

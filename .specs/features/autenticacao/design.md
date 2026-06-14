# Autenticação — Design

**Spec:** `.specs/features/autenticacao/spec.md`
**Status:** Draft

---

## Architecture Overview

OAuth-only via Google. Devise gerencia sessões; OmniAuth gerencia o handshake. Sem registro próprio, sem senha. Resultado da partida é salvo em `GameResult` quando o usuário logado chega à tela de resultado.

```mermaid
graph TD
    A[Visitante / Convidado] -->|"Jogar agora"| B[MatchesController#start]
    A -->|"Login com Google"| C[/auth/google_oauth2]
    C --> D[Google OAuth]
    D -->|callback| E[Users::OmniauthCallbacksController]
    E -->|novo usuário| F[NicknamesController#new]
    E -->|usuário existente| G[root_path]
    F -->|nickname salvo| G
    B --> H[Partida em andamento]
    H -->|5ª resposta + advance| I[MatchesController#next_question]
    I -->|finished? && user_signed_in?| J[(GameResult salvo no BD)]
    I --> K[Tela de resultado]
    K -->|convidado| L[CTA: Entrar no ranking]
    K -->|logado| M[✓ Resultado salvo]
    L --> C
```

---

## Code Reuse Analysis

| Componente existente | Localização | Como reutilizar |
|----------------------|-------------|-----------------|
| `MatchesController` | `app/controllers/matches_controller.rb` | Adicionar save de `GameResult` em `#next_question` quando `finished? && user_signed_in?` |
| `AnswersController` | `app/controllers/answers_controller.rb` | Sem modificação |
| `Quiz::MatchState` | `app/models/quiz/match_state.rb` | `#score`, `#correct_count`, `#finished?` já expostos — usados ao salvar GameResult |
| `matches/_result.html.erb` | `app/views/matches/_result.html.erb` | Adicionar bloco condicional `user_signed_in?` para mensagem / CTA |
| `matches/_home.html.erb` | `app/views/matches/_home.html.erb` | Adicionar link "Login com Google" para convidados |
| Layout `matches` | `app/views/layouts/matches.html.erb` | Adicionar `current_user` no header (nickname + logout) |
| `ApplicationController` | `app/controllers/application_controller.rb` | Adicionar `before_action :store_user_location!` e helpers Devise |
| `config/routes.rb` | `config/routes.rb` | Adicionar `devise_for`, rota de ranking, rota de nickname |

---

## Componentes

### 1. Gems (Gemfile)

- **`devise`** — gestão de sessão, `current_user`, `user_signed_in?`, `authenticate_user!`
- **`omniauth-google-oauth2`** — provider OAuth do Google
- **`omniauth-rails_csrf_protection`** — segurança obrigatória no Rails 7+

---

### 2. User (model)

- **Purpose:** Identidade persistente do jogador; criado via OAuth Google.
- **Location:** `app/models/user.rb`, `db/migrate/*_devise_create_users.rb`
- **Devise modules:** `:omniauthable, :rememberable, :trackable`
  - ⚠️ Sem `:database_authenticatable` (não há senha), sem `:registerable`, sem `:recoverable`
  - Isso exige configuração especial do Devise (ver Tech Decisions abaixo)
- **Interfaces:**
  - `User.from_omniauth(auth)` — find_or_create por `provider` + `uid`
  - `user.nickname_set?` — booleano para o redirect pós-primeiro-login
- **Reuses:** padrão `from_omniauth` do OmniAuth Guide

**Schema:**

```ruby
create_table :users do |t|
  # OmniAuth
  t.string :provider, null: false
  t.string :uid,      null: false

  # Perfil
  t.string :email,      null: false
  t.string :nickname,   limit: 18
  t.boolean :nickname_set, null: false, default: false
  t.string :avatar_url

  # Devise :rememberable
  t.datetime :remember_created_at

  # Devise :trackable
  t.integer  :sign_in_count, default: 0, null: false
  t.datetime :current_sign_in_at
  t.datetime :last_sign_in_at
  t.string   :current_sign_in_ip
  t.string   :last_sign_in_ip

  t.timestamps
end
add_index :users, [:provider, :uid], unique: true
add_index :users, :email,    unique: true
add_index :users, :nickname, unique: true
```

---

### 3. GameResult (model)

- **Purpose:** Persiste o resultado de cada partida de um usuário logado.
- **Location:** `app/models/game_result.rb`, `db/migrate/*_create_game_results.rb`
- **Interfaces:**
  - `GameResult.create!(user:, score:, correct_count:, questions_count:)`
- **Reuses:** `Quiz::MatchState#score`, `#correct_count`

**Schema:**

```ruby
create_table :game_results do |t|
  t.references :user,   null: false, foreign_key: true
  t.integer :score,          null: false
  t.integer :correct_count,  null: false
  t.integer :questions_count, null: false, default: 5
  t.datetime :played_at,     null: false, default: -> { 'CURRENT_TIMESTAMP' }
  t.timestamps
end
add_index :game_results, [:user_id, :played_at]
```

---

### 4. Users::OmniauthCallbacksController

- **Purpose:** Recebe o callback do Google, cria/recupera usuário, decide redirect.
- **Location:** `app/controllers/users/omniauth_callbacks_controller.rb`
- **Interfaces:**
  - `#google_oauth2` — action do callback
- **Lógica:**
  ```
  auth = request.env["omniauth.auth"]
  @user = User.from_omniauth(auth)
  if @user.persisted?
    sign_in_and_redirect @user, event: :authentication
    if @user.nickname_set?
      redirect to origin (session[:user_return_to] or root)
    else
      redirect_to new_nickname_path
    end
  else
    redirect_to root_path, alert: "Não foi possível autenticar. Tente novamente."
  end
  ```

---

### 5. NicknamesController

- **Purpose:** Coleta e valida o nickname na primeira entrada.
- **Location:** `app/controllers/nicknames_controller.rb`
- **Actions:**
  - `GET  /nickname/new` → form com nome do Google pré-preenchido
  - `POST /nickname`     → valida e salva; redireciona para `root_path`
- **Before action:** `authenticate_user!`
- **Reuses:** validações do `User` model (unicidade, charset, tamanho)
- **View:** `app/views/nicknames/new.html.erb` — usa layout `matches` (estilo consistente)

---

### 6. RankingController (básico — suficiente para AUTH-03)

- **Purpose:** Lista os melhores resultados de partidas; visível para todos.
- **Location:** `app/controllers/ranking_controller.rb`
- **Actions:**
  - `GET /ranking` → lista `GameResult.order(score: :desc).limit(50).includes(:user)`
- **View:** `app/views/ranking/index.html.erb` — layout `matches`, tabela simples
- **Note:** Feature "Ranking completo" (M2 fase 2) vai expandir isso com ranking semanal, paginação, etc.

---

### 7. MatchesController (modificações)

Dois pontos de toque:

**a) `#next_question` — salvar resultado ao terminar:**
```ruby
def next_question
  return redirect_to(root_path) if @match.nil?
  @match.advance!
  save_match

  if @match.finished? && user_signed_in?
    GameResult.create!(
      user:           current_user,
      score:          @match.score,
      correct_count:  @match.correct_count,
      questions_count: @match.total
    )
  end

  @screen = @match.screen
  render :show
end
```

**b) `#show` — passar `@is_guest` para a view:**
```ruby
@is_guest = !user_signed_in?
```

---

### 8. Views modificadas

**`matches/_result.html.erb`** — bloco condicional no "bottom card":

```erb
<% if @is_guest %>
  <p class="text-center text-sm text-gray-500">
    Você jogou como convidado — resultado não salvo no ranking.
  </p>
  <%= link_to "Entrar no ranking com Google",
        user_google_oauth2_omniauth_authorize_path,
        method: :post, class: "btn-share" %>
<% else %>
  <p class="text-center text-sm text-verde font-bold">✓ Resultado salvo no ranking!</p>
<% end %>
```

**`matches/_home.html.erb`** — link de login discreto (AUTH-14, P2):

```erb
<% unless user_signed_in? %>
  <%= link_to "Login com Google",
        user_google_oauth2_omniauth_authorize_path,
        method: :post,
        class: "text-sm text-gray-400 underline mt-2" %>
<% else %>
  <p class="text-sm text-gray-500">Olá, <%= current_user.nickname %>!</p>
<% end %>
```

**`matches/layouts/matches.html.erb`** — logout no header (quando logado):

```erb
<% if user_signed_in? %>
  <%= button_to "Sair", destroy_user_session_path, method: :delete,
        class: "text-xs text-gray-400" %>
<% end %>
```

---

## Data Flow — Primeiro Login

```
1. Usuário clica "Login com Google"
2. POST /auth/google_oauth2          ← CSRF protegido
3. Redirect → Google
4. Google → GET /auth/google_oauth2/callback
5. OmniauthCallbacksController#google_oauth2
   ├── User.from_omniauth(auth) → cria usuário (nickname_set: false)
   ├── sign_in(user)
   └── redirect_to new_nickname_path
6. NicknamesController#new → form (nome do Google pré-preenchido)
7. POST /nickname → User.update!(nickname:, nickname_set: true)
8. redirect_to root_path
```

---

## Error Handling

| Cenário | Tratamento | O que o usuário vê |
|---------|------------|---------------------|
| OAuth cancelado / falha Google | `redirect_to root_path, alert:` | Mensagem de erro na home |
| Nickname já existe | Validação + sugestão no form | "Esse nickname já foi usado. Que tal 'Joao_42'?" |
| Nickname inválido (charset) | Validação no model | "Use apenas letras, números, _ ou -" |
| Usuário perde sessão durante jogo | Jogo continua como convidado; resultado não salvo | — (sem bloqueio) |
| Race condition em nickname único | `rescue ActiveRecord::RecordNotUnique` → retry com sufixo | Transparente |

---

## Tech Decisions

| Decisão | Escolha | Rationale |
|---------|---------|-----------|
| Devise sem `:database_authenticatable` | Usar `:omniauthable` + modelo customizado sem `encrypted_password` | Evita coluna de senha desnecessária; simplifica UX (não há senha para esquecer) |
| Salvar GameResult em `#next_question` | Após `@match.advance!` quando `finished?` | É o único ponto onde o jogo termina no fluxo `matches`; `AnswersController` não vê o fim |
| Ranking básico incluído nesta feature | `GET /ranking` com lista simples | AUTH-03 exige que ranking seja acessível; a feature "Ranking completo" vai enriquecer |
| `omniauth-rails_csrf_protection` | Obrigatório | Rails 7 exige proteção CSRF em rotas OmniAuth com `method: :post` |
| Nickname pré-preenchido com `first_name` do Google | `auth.info.first_name` | Nome completo é longo e expõe dados; primeiro nome é natural como apelido |
| `session[:user_return_to]` para redirect pós-login | Padrão Devise | Permite redirecionar para onde o usuário estava antes de clicar "Login" |

---

## Diagrama de Rotas (adições ao `config/routes.rb`)

```ruby
devise_for :users,
  controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
  skip: [:sessions, :passwords, :registrations, :confirmations]

# Logout manual (Devise só cria se :sessions não for skipped)
delete "/logout", to: "devise/sessions#destroy", as: :destroy_user_session

get  "/nickname/new", to: "nicknames#new",    as: :new_nickname
post "/nickname",     to: "nicknames#create",  as: :nickname

get "/ranking", to: "ranking#index", as: :ranking
```

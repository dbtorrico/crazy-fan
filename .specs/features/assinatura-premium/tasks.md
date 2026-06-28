# Assinatura Premium R$5/mês — Tasks

**Design:** `.specs/features/assinatura-premium/design.md`
**Spec:** `.specs/features/assinatura-premium/spec.md`
**Testing:** `.specs/codebase/TESTING.md`
**Status:** Ready for execution

---

## Execution Plan

```
T1 (migration + User#premium?)            ← fundação; tudo depende disto
  └─► T2 (gem MP + lib wrapper)           ← pré-requisito do controller
        └─► T3 (PaymentsController)       ← depende de T1 + T2
              ├─► T4 [P] (views + CSS)    ← depende de T3 (rotas já existem)
              └─► T4 [P] (testes)         ← paralelizável com views
T5 (verificação e2e + suíte verde)        ← após T3 + T4
```

---

## Task Breakdown

### T1: Migration + `User#premium?` + `unlimited_energy?`

**What:** Adicionar `premium_until:datetime` (nullable) à tabela `users` via migration. Implementar `User#premium?` e substituir o `false` hardcoded em `unlimited_energy?`.

**Where:**
- `db/migrate/TIMESTAMP_add_premium_until_to_users.rb`
- `app/models/user.rb` (linhas 42-44)
- `test/models/user_test.rb`

**Depends on:** None

**Reuses:** Lógica de `Time.current` já usada em `current_energy` / `next_recharge_at`

**Requirement:** SUB-P1 (AC4, AC5, AC6), SUB-P2 (AC1, AC2, AC4)

**Done when:**
- [ ] Migration `add_premium_until_to_users` existe com `add_column :users, :premium_until, :datetime`
- [ ] `User#premium?` retorna `true` quando `premium_until > Time.current`, `false` nos demais casos
- [ ] `User#unlimited_energy?` delega para `premium?`
- [ ] Testes unit cobrem: `premium_until nil`, `premium_until` no passado, `premium_until` no futuro
- [ ] `bin/rails test` verde

**Tests:** unit (`test/models/user_test.rb`) · **Gate:** quick

**Commit:** `feat(sub): migration premium_until + User#premium? e unlimited_energy?`

---

### T2: Gem Mercado Pago + lib wrapper

**What:** Adicionar `gem "mercadopago"` ao Gemfile e criar `lib/mercado_pago/client.rb` com os dois métodos: `create_pix_payment` e `get_payment`. O wrapper isola o SDK real para facilitar stub em testes.

**Where:**
- `Gemfile` (+ `bundle install`)
- `lib/mercado_pago/client.rb`
- `.env.example` (adicionar `MP_ACCESS_TOKEN=`)
- `test/lib/mercado_pago/client_test.rb` (stub HTTP)

**Depends on:** T1 (nenhuma dependência técnica, mas sequência lógica)

**Reuses:** Pattern de `ENV.fetch` já usado no app

**Requirement:** SUB-P1 (AC2), SUB-P3 (AC1, AC4)

**Done when:**
- [ ] `gem "mercadopago"` no Gemfile e `bundle install` sem conflito
- [ ] `lib/mercado_pago/client.rb` com `create_pix_payment(user:, external_reference:)` e `get_payment(id)`
- [ ] `ENV.fetch("MP_ACCESS_TOKEN")` sem fallback (falha no boot se ausente — intencional)
- [ ] `.env.example` documenta `MP_ACCESS_TOKEN`
- [ ] Teste unit do client usa stub (não chama API real); cobre chamada de criação e de re-query
- [ ] `bin/rails test` verde

**Tests:** unit (stub HTTP) · **Gate:** quick

**Commit:** `feat(sub): gem mercadopago + lib wrapper com stub testável`

---

### T3: PaymentsController + rotas

**What:** Implementar `PaymentsController` com as três actions (`create`, `show`, `webhook`). Registrar rotas. Skip de CSRF só no webhook.

**Where:**
- `app/controllers/payments_controller.rb`
- `config/routes.rb`
- `test/controllers/payments_controller_test.rb`

**Depends on:** T1, T2

**Reuses:** Pattern `skip_before_action :verify_authenticity_token` (ver ApplicationController); `authenticate_user!` do Devise

**Requirement:** SUB-P1 (AC2, AC3, AC7), SUB-P3 (AC1, AC2, AC3, AC4)

**Done when:**
- [ ] `POST /payments/create` cria pagamento no MP (via lib wrapper), guarda dados na session, redireciona para `GET /payments/:id`
- [ ] `GET /payments/:id` lê QR code da session e passa para a view
- [ ] `POST /payments/webhook` faz re-query no MP, ativa premium se `status == "approved"`, responde 200 em todos os casos
- [ ] Webhook ignora notificações com `type != "payment"` (responde 200)
- [ ] Webhook não ativa premium para pagamentos não aprovados
- [ ] Webhook extrai `user_id` de `external_reference` e chama `user.update!(premium_until: +30d)`
- [ ] Rota do webhook não é acessível por GET
- [ ] Testes integration cobrem: webhook approved → premium ativado; webhook não-approved → sem mudança; type diferente → 200 sem efeito
- [ ] `bin/rails test` verde

**Tests:** integration · **Gate:** quick

**Commit:** `feat(sub): PaymentsController — criação Pix, QR code e webhook`

---

### T4a: Views + CSS [P] ← paralelizável com T4b

**What:** Tela do QR code (`payments/show`), CTA de assinatura no `:no_energy`, badge premium no header, indicador de expiração próxima.

**Where:**
- `app/views/payments/show.html.erb` (nova)
- `app/views/matches/_no_energy.html.erb` (adiciona bloco sub-cta)
- `app/views/layouts/matches.html.erb` (badge premium)
- `app/assets/stylesheets/torcedor_maluco.css` (novas classes)

**Depends on:** T3 (rotas precisam existir para os helpers de path)

**Reuses:** `.btn`, `.home-card`, tokens de cor (verde, amarelo, azul do `:root`)

**Requirement:** SUB-P1 (AC1, AC2), SUB-P2 (AC1, AC2, AC3, AC4)

**Done when:**
- [ ] Tela `payments/show` exibe QR code (img base64) + campo de texto com código + botão "Copiar" (clipboard JS)
- [ ] `:no_energy` exibe CTA "🏆 Assinar por R$5/mês" (button_to `create_payments_path`, `turbo: false`) para usuários não-premium
- [ ] `:no_energy` exibe "⭐ Energia ilimitada ✅" e omite CTA quando usuário é premium
- [ ] Header exibe `⭐ Premium` quando `current_user&.premium?`
- [ ] Quando `premium_until` ≤ 3 dias, exibe aviso de expiração
- [ ] CSS: `.pay-*`, `.sub-cta`, `.btn-premium`, `.badge-premium` no arquivo de tokens existente
- [ ] Visual testado manualmente no preview

**Tests:** none (views estáticas) · Verificação: visual no preview · **Gate:** quick (sem regressão)

**Commit:** `feat(sub): views Pix QR code, CTA premium e badge no header`

---

### T4b: Testes de model e controller [P] ← paralelizável com T4a

**What:** Consolidar e complementar os testes das tasks anteriores. Garantir que o comportamento de `debit_energy!` com premium ativo está coberto.

**Where:**
- `test/models/user_test.rb` (complementar T1 com teste de `debit_energy!` premium)
- `test/controllers/payments_controller_test.rb` (complementar T3)

**Depends on:** T3

**Done when:**
- [ ] `debit_energy!` com `premium? == true` retorna `true` sem debitar (teste unit)
- [ ] `debit_energy!` com premium expirado debita normalmente (teste unit)
- [ ] Controller test cobre `#create` com MP stub retornando sucesso e falha
- [ ] `bin/rails test` verde (todos os testes existentes + novos)

**Tests:** unit + integration · **Gate:** quick

**Commit:** `test(sub): cobertura completa de premium — energia, controller e webhook`

---

### T5: Verificação e2e + suíte completa

**What:** Verificação manual com sandbox do Mercado Pago + suíte de testes completa. Atualizar ROADMAP.md e STATE.md.

**Where:**
- `.env` local (credenciais sandbox do MP)
- `.specs/project/ROADMAP.md`
- `.specs/project/STATE.md`

**Depends on:** T4a, T4b

**Done when:**
- [ ] `bin/rails test` → verde (todos os testes, contagem igual ou maior)
- [ ] Flow manual sandbox: acesso a `:no_energy` → clica "Assinar" → vê QR code → simula pagamento aprovado via painel MP sandbox → webhook dispara → `premium_until` setado → badge aparece
- [ ] ROADMAP.md: "Assinatura R$5/mês" e "Jogadas ilimitadas" marcados DONE
- [ ] STATE.md: decisão de `external_reference` como `user_<id>_<timestamp>` registrada

**Tests:** e2e manual (sandbox MP) · **Gate:** quick + visual

**Commit:** `docs: M3 assinatura premium marcada DONE no roadmap`

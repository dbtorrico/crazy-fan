# Assinatura Premium R$5/mês — Design

**Spec:** `.specs/features/assinatura-premium/spec.md`
**Status:** Approved

---

## Architecture Overview

A feature adiciona um **PaymentsController** responsável por criar pagamentos Pix no Mercado Pago e receber webhooks. O model `User` ganha a coluna `premium_until` e `unlimited_energy?` passa a lê-la. Nenhum novo model de domínio necessário para Pix avulso.

```
User (browser)
  │
  ├─ POST /payments/create ──► PaymentsController#create
  │                                │
  │                                └─► MercadoPago::SDK (POST /v1/payments)
  │                                         │
  │                                    {qr_code, qr_code_base64, payment_id}
  │                                         │
  │                          ◄─ redirect_to /payments/:id
  │
  └─ GET /payments/:id ──► PaymentsController#show
       │                        └─ exibe QR code + copia-e-cola (session[:pending_payment_id])
       │
  [usuário paga no banco]
       │
MercadoPago ──► POST /payments/webhook ──► PaymentsController#webhook
                                                │
                                           re-query GET /v1/payments/:id
                                                │ status == "approved"?
                                                ├─ sim → user.update!(premium_until: +30d)
                                                └─ não → log + 200 OK
```

---

## Components

### 1. Migration — `add_premium_until_to_users`

**What:** Adiciona `premium_until:datetime` (nullable) à tabela `users`.
**Where:** `db/migrate/TIMESTAMP_add_premium_until_to_users.rb`
**Depends on:** None

---

### 2. `User#premium?` e `unlimited_energy?`

**What:** Dois métodos no `User`:
- `premium?` → `premium_until.present? && premium_until > Time.current`
- `unlimited_energy?` → delega para `premium?` (substituindo o `false` hardcoded)

**Where:** `app/models/user.rb`
**Depends on:** migration

---

### 3. Gem `mercadopago`

**What:** Adicionar `gem "mercadopago"` ao Gemfile. Wrapper no `lib/mercado_pago/client.rb` para isolar chamadas de API (facilita stub em testes).

```ruby
# lib/mercado_pago/client.rb
module MercadoPago
  class Client
    def initialize
      @sdk = ::MercadoPago::SDK.new(ENV.fetch("MP_ACCESS_TOKEN"))
    end

    def create_pix_payment(user:, external_reference:)
      @sdk.payment.create(
        transaction_amount: 5.0,
        payment_method_id:  "pix",
        payer:              { email: user.email },
        description:        "Torcedor Maluco Premium — 30 dias",
        external_reference: external_reference
      )
    end

    def get_payment(id)
      @sdk.payment.get(id)
    end
  end
end
```

**Where:** `lib/mercado_pago/client.rb` + `Gemfile`

---

### 4. `PaymentsController`

**What:** Controller com três actions:

```ruby
class PaymentsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :show]
  skip_before_action :verify_authenticity_token, only: [:webhook]

  # POST /payments/create
  def create
    ext_ref = "user_#{current_user.id}_#{Time.current.to_i}"
    result  = MercadoPago::Client.new.create_pix_payment(
                user: current_user, external_reference: ext_ref)

    if result[:status] == 201
      data = result[:response]
      session[:pending_payment_id] = data["id"]
      session[:pending_payment_qr] = data.dig("point_of_interaction",
                                               "transaction_data", "qr_code")
      session[:pending_payment_b64] = data.dig("point_of_interaction",
                                                "transaction_data", "qr_code_base64")
      redirect_to payment_path(data["id"])
    else
      redirect_to root_path, alert: "Erro ao gerar Pix. Tente novamente."
    end
  end

  # GET /payments/:id
  def show
    @payment_id  = params[:id]
    @qr_code     = session[:pending_payment_qr]
    @qr_b64      = session[:pending_payment_b64]
    render :show
  end

  # POST /payments/webhook  (sem CSRF — chamado pelo MP)
  def webhook
    return head :ok unless params[:type] == "payment"

    payment_id = params.dig(:data, :id)
    result     = MercadoPago::Client.new.get_payment(payment_id)
    payment    = result[:response]

    if result[:status] == 200 && payment["status"] == "approved"
      activate_premium_for(payment["external_reference"])
    else
      Rails.logger.warn("[Webhook] Pagamento #{payment_id} não aprovado: #{payment["status"]}")
    end

    head :ok
  end

  private

  def activate_premium_for(external_reference)
    return unless external_reference&.start_with?("user_")
    user_id = external_reference.split("_")[1].to_i
    user    = User.find_by(id: user_id)
    return Rails.logger.warn("[Webhook] User não encontrado: #{user_id}") unless user

    user.update!(premium_until: Time.current + 30.days)
    Rails.logger.info("[Webhook] Premium ativado para user #{user_id} até #{user.premium_until}")
  end
end
```

**Where:** `app/controllers/payments_controller.rb`
**Depends on:** gem mercadopago, lib wrapper, migration

---

### 5. Views

#### `payments/show.html.erb` — tela do QR code

```erb
<div class="pay-wrap">
  <h2>Pague R$5 via Pix</h2>
  <img src="data:image/png;base64,<%= @qr_b64 %>" alt="QR Code Pix" class="pay-qr">
  <p class="pay-label">Ou copie o código:</p>
  <div class="pay-copy">
    <input readonly value="<%= @qr_code %>" class="pay-input" id="pix-code">
    <button onclick="navigator.clipboard.writeText(document.getElementById('pix-code').value)"
            class="pay-btn">Copiar</button>
  </div>
  <p class="pay-hint">Após pagar, aguarde alguns segundos e recarregue a página.</p>
  <%= link_to "← Voltar", root_path, class: "pay-back" %>
</div>
```

#### `matches/_no_energy.html.erb` — CTA de assinatura

Adicionar bloco ao partial existente:

```erb
<div class="sub-cta">
  <%= button_to "🏆 Assinar por R$5/mês", create_payments_path,
        method: :post,
        class: "btn btn-premium",
        data: { turbo: false } %>
  <p class="sub-hint">Jogadas ilimitadas por 30 dias. Pix instantâneo.</p>
</div>
```

#### Indicador de premium no header

Em `layouts/matches.html.erb` (ou `matches/_header.html.erb`): adicionar `<span class="badge-premium">⭐ Premium</span>` condicional a `current_user&.premium?`.

---

### 6. Routes

```ruby
resources :payments, only: [:show] do
  collection do
    post :create
    post :webhook
  end
end
```

---

### 7. CSS — classes novas

Adicionar em `torcedor_maluco.css`:
- `.pay-wrap`, `.pay-qr`, `.pay-copy`, `.pay-input`, `.pay-btn`, `.pay-hint`, `.pay-back`
- `.sub-cta`, `.btn-premium`, `.sub-hint`
- `.badge-premium`

---

## Discovered State (pré-condições)

| Fato verificado | Implicação |
|----------------|------------|
| `User#unlimited_energy?` retorna `false` com comentário "Gancho do M3" (`user.rb:42`) | Substituir por `premium?` — 1 linha |
| `User#debit_energy!` já faz `return true if unlimited_energy?` (`user.rb:48`) | Energia ilimitada funciona automaticamente após `unlimited_energy?` retornar `true` |
| `MatchesController#consume_energy!` chama `unlimited_energy?` (`matches_controller.rb:69`) | Fluxo de partida já responde ao premium sem alteração |
| `ENV.fetch("GOOGLE_CLIENT_ID", "")` usa fallback vazio (STATE.md) | Usar `ENV.fetch("MP_ACCESS_TOKEN")` sem fallback — falha no boot se ausente (intencional) |
| App usa Turbo; `matches#show` renderiza partials via Turbo Frame `#match` | Botão "Assinar" usa `data: { turbo: false }` para navegação full-page |

---

## Test Strategy

| Componente | Tipo | O que cobre |
|-----------|------|-------------|
| `User#premium?` e `unlimited_energy?` | unit | `premium_until` nil, passado, futuro |
| `PaymentsController#webhook` | integration | approved → ativa premium; não-approved → não ativa; `type` diferente → ignora |
| `MercadoPago::Client` | unit (stub HTTP) | Não chama MP real em testes |
| Tela QR code | none (view estática) | — |
| CTA no `:no_energy` | none (view estática) | — |

Sandbox do Mercado Pago para testes manuais (E2E). Credenciais sandbox em `.env.test` ou variável de ambiente.

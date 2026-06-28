# Assinatura Premium R$5/mês (Mercado Pago Pix) — Specification

**Feature ID prefix:** `SUB`
**Milestone:** M3 — Monetização
**Status:** Specified
**Decisões de base:**
1. **Modelo:** Pix avulso mensal — usuário paga R$5 manualmente; sem recorrência automática.
2. **Ordem:** Assinatura antes do AdSense — receita direta primeiro.
3. **Gancho já existente:** `User#unlimited_energy?` (retorna `false` hoje) é o ponto de entrada da feature no código.

---

## Problem Statement

O app tem um teto de 5 jogadas/dia que frustra usuários engajados — esse atrito é o gancho de conversão para o premium. Hoje não há nenhum caminho de pagamento: `unlimited_energy?` está hardcoded como `false`. A feature ativa esse caminho: o usuário paga R$5 via Pix, recebe confirmação automática via webhook do Mercado Pago, e passa a ter jogadas ilimitadas por 30 dias.

---

## Goals

- [ ] Usuário logado pode iniciar um pagamento Pix de R$5 direto no app
- [ ] App exibe QR code + código copia-e-cola gerado pelo Mercado Pago
- [ ] Webhook do MP confirma o pagamento e ativa premium (`premium_until`) automaticamente
- [ ] `User#unlimited_energy?` passa a verificar `premium_until > Time.current`
- [ ] UI indica status premium (header ou tela de energia)
- [ ] Tela de energia esgotada (`:no_energy`) exibe o CTA "Assinar por R$5"

## Out of Scope

| O que | Razão |
|-------|-------|
| Assinatura recorrente automática (pre-approval MP) | Decidido: Pix avulso por ora; migrar quando houver base |
| Cancelamento de assinatura pelo usuário | Pix avulso expira naturalmente; não há contrato |
| Reembolso | Fluxo manual fora do app |
| Desconto ou cupom | M4+ |
| Premium para convidados (sem conta) | Pix exige identidade; sem OAuth não tem como vincular |
| Remoção de anúncios | Não há AdSense ainda; a promessa "sem anúncios" fica para quando AdSense for ativado |
| Página de gestão de assinatura | Tela simples de status; gestão completa é M4 |

---

## User Stories

### SUB-P1: Pagamento Pix e ativação automática ⭐ MVP

**User Story:** Como jogador logado sem energia, quero pagar R$5 via Pix e ter jogadas ilimitadas ativadas automaticamente, para não precisar esperar 2h entre partidas.

**Acceptance Criteria:**

1. WHEN o usuário logado está na tela `:no_energy` THEN um CTA "🏆 Assinar por R$5/mês" SHALL aparecer abaixo do contador de recarga
2. WHEN o usuário clica no CTA THEN o app SHALL criar um pagamento Pix no Mercado Pago e redirecionar para uma tela exibindo o QR code e o código copia-e-cola
3. WHEN o pagamento é aprovado pelo Mercado Pago THEN o webhook SHALL ser chamado e o app SHALL definir `user.premium_until = Time.current + 30.days` e salvar
4. WHEN `premium_until > Time.current` THEN `User#unlimited_energy?` SHALL retornar `true`
5. WHEN `unlimited_energy?` é `true` THEN `User#debit_energy!` SHALL retornar `true` sem debitar energia (comportamento já implementado)
6. WHEN o premium expirou (`premium_until` no passado ou `nil`) THEN `unlimited_energy?` SHALL retornar `false` e as regras normais de energia se aplicam
7. WHEN o webhook recebe uma notificação que não é de pagamento aprovado THEN o app SHALL responder HTTP 200 e não alterar o usuário

**Independent Test:** Pagar via sandbox do MP → webhook dispara → `premium_until` setado → tela de energia recarregada mostra "Energia ilimitada".

---

### SUB-P2: Indicador de status premium ⭐ MVP

**User Story:** Como assinante, quero ver claramente que meu premium está ativo e quando expira, para ter confiança no produto.

**Acceptance Criteria:**

1. WHEN o usuário é premium THEN o header SHALL exibir um badge "⭐ Premium" no lugar ou ao lado do indicador de energia
2. WHEN o usuário é premium THEN a tela de energia (`:no_energy`) SHALL mostrar "Energia ilimitada ✅" em vez do contador de recarga e do CTA de assinatura
3. WHEN faltam ≤ 3 dias para expirar THEN o app SHALL exibir "Premium expira em N dia(s)" na tela de energia ou no header
4. WHEN o premium expirou THEN o badge desaparece e o comportamento volta ao normal (sem tela de erro)

**Independent Test:** Setar `premium_until` via console → verificar badge no header e tela de energia em ambos os estados (ativo / expirado).

---

### SUB-P3: Segurança do webhook

**User Story:** Como dono do produto, quero que apenas notificações legítimas do Mercado Pago ativem o premium, para evitar fraudes.

**Acceptance Criteria:**

1. WHEN o webhook recebe uma notificação THEN o app SHALL buscar o pagamento pelo `data.id` diretamente na API do MP (re-query) antes de confiar no status recebido no body
2. WHEN o re-query retorna `status != "approved"` THEN o premium não SHALL ser ativado
3. WHEN a rota do webhook é acessada por GET (browser) THEN SHALL retornar 404 ou rota não existir
4. WHEN o `data.id` do pagamento não existe na API do MP THEN SHALL logar aviso e responder 200 (não quebrar — MP pode retentar)

**Independent Test:** Enviar POST ao endpoint com `data.id` inválido → premium não ativado; com `data.id` de pagamento approved em sandbox → premium ativado.

---

## Data Model

### Mudança em `users`

```
premium_until :datetime, default: nil
```

- `nil` = nunca assinou ou expirou (tratado como free)
- `datetime` no passado = expirou (free)
- `datetime` no futuro = ativo (premium)

Nenhuma tabela nova. Nenhum model de assinatura separado (complexidade desnecessária para Pix avulso).

---

## Integration: Mercado Pago

- **Gem:** `mercadopago` (SDK Ruby oficial)
- **Ambiente:** credenciais separadas por env (`MP_ACCESS_TOKEN` — sandbox em dev/test, produção em prod)
- **Endpoint de criação:** `POST /v1/payments` com `payment_method_id: "pix"`, `transaction_amount: 5.0`, `payer.email`
- **Resposta:** `point_of_interaction.transaction_data.qr_code` (texto) + `qr_code_base64` (imagem)
- **Webhook URL:** `POST /payments/webhook` — registrada no painel MP como notification URL
- **Re-query:** `GET /v1/payments/:id` para confirmar status antes de ativar premium

---

## Routes

```ruby
resources :payments, only: [] do
  collection do
    post :create   # cria pagamento Pix no MP → redireciona para :show
    post :webhook  # recebe notificação do MP (skip CSRF)
  end
  member do
    get :show      # exibe QR code + copia-e-cola
  end
end
```

---

## Tech Debt Registrado

- Webhook não tem verificação de assinatura MP (`x-signature` header) — re-query compensa por ora. Adicionar HMAC quando MP liberar documentação atualizada para o BR.
- `premium_until` não tem histórico de pagamentos — sem auditoria. Criar `Payment` model em M4 se necessário.

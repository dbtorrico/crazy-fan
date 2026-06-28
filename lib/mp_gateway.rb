require "mercadopago"

# Wrapper fino sobre o SDK mercadopago v2 para isolar chamadas HTTP.
# Aceita `sdk:` para injeção de dependência em testes (sem hit real na API).
class MpGateway
  PIX_AMOUNT      = 5.0
  PREMIUM_DESC    = "Torcedor Maluco Premium — 30 dias".freeze

  def initialize(sdk: nil)
    @sdk = sdk || ::MercadoPago::Client.new(
      ENV.fetch("MP_CLIENT_ID"),
      ENV.fetch("MP_CLIENT_SECRET")
    )
  end

  # Cria um pagamento Pix de R$5 no Mercado Pago.
  # Retorna { ok: true, id:, qr_code:, qr_code_base64: } ou { ok: false, error: }.
  def create_pix_payment(user:, external_reference:)
    response = @sdk.post("/v1/payments", {
      transaction_amount: PIX_AMOUNT,
      payment_method_id:  "pix",
      payer:              { email: user.email },
      description:        PREMIUM_DESC,
      external_reference: external_reference
    })

    if response["id"].present?
      tx = response.dig("point_of_interaction", "transaction_data") || {}
      { ok: true,
        id:              response["id"],
        qr_code:         tx["qr_code"],
        qr_code_base64:  tx["qr_code_base64"] }
    else
      Rails.logger.error("[MpGateway] Erro ao criar pagamento: #{response['message']}")
      { ok: false, error: response["message"] }
    end
  rescue => e
    Rails.logger.error("[MpGateway] Exceção ao criar pagamento: #{e.message}")
    { ok: false, error: e.message }
  end

  # Busca um pagamento pelo ID para re-validar status (usado no webhook).
  # Retorna o hash do pagamento ou nil em caso de erro.
  def get_payment(id)
    @sdk.notification(id.to_s)
  rescue => e
    Rails.logger.error("[MpGateway] Erro ao buscar pagamento #{id}: #{e.message}")
    nil
  end
end

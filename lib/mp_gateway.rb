require "net/http"
require "json"

# Wrapper fino sobre a API do Mercado Pago usando Bearer token.
# Aceita `http:` para injeção de dependência em testes (sem hit real na API).
class MpGateway
  BASE_URL     = "https://api.mercadopago.com".freeze
  PIX_AMOUNT   = 5.0
  PREMIUM_DESC = "Torcedor Maluco Premium — 30 dias".freeze

  def initialize(http: nil)
    @http  = http
    @token = http ? nil : ENV.fetch("MP_ACCESS_TOKEN")
  end

  # Cria um pagamento Pix de R$5 no Mercado Pago.
  # Retorna { ok: true, id:, qr_code:, qr_code_base64: } ou { ok: false, error: }.
  def create_pix_payment(user:, external_reference:)
    response = mp_post("/v1/payments", {
      transaction_amount: PIX_AMOUNT,
      payment_method_id:  "pix",
      payer:              { email: user.email },
      description:        PREMIUM_DESC,
      external_reference: external_reference
    })
    if response["id"].present?
      tx = response.dig("point_of_interaction", "transaction_data") || {}
      { ok: true, id: response["id"], qr_code: tx["qr_code"], qr_code_base64: tx["qr_code_base64"] }
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
    mp_get("/v1/payments/#{id}")
  rescue => e
    Rails.logger.error("[MpGateway] Erro ao buscar pagamento #{id}: #{e.message}")
    nil
  end

  private

  def mp_post(path, data)
    return @http.post(path, data) if @http
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{@token}"
    req["Content-Type"]  = "application/json"
    req.body = data.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
    JSON.parse(res.body)
  end

  def mp_get(path)
    return @http.get(path) if @http
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@token}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
    JSON.parse(res.body)
  end
end

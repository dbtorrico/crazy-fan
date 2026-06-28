class PaymentsController < ApplicationController
  layout "matches"
  before_action :authenticate_user!, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:webhook]

  # POST /payments/create
  def create
    ext_ref = "user_#{current_user.id}_#{Time.current.to_i}"
    result  = MpGateway.new.create_pix_payment(user: current_user, external_reference: ext_ref)

    if result[:ok]
      @payment_id     = result[:id]
      @qr_code        = result[:qr_code]
      @qr_code_base64 = result[:qr_code_base64]
      render :show
    else
      redirect_to root_path, alert: "Erro ao gerar Pix. Tente novamente."
    end
  end

  # POST /payments/webhook  (sem CSRF — chamado pelo Mercado Pago)
  def webhook
    return head :ok unless params[:type] == "payment"

    payment_id = params.dig(:data, :id)
    payment    = MpGateway.new.get_payment(payment_id)

    if payment&.dig("status") == "approved"
      activate_premium_for(payment["external_reference"])
    else
      status = payment&.dig("status") || "nil"
      Rails.logger.warn("[Webhook] Pagamento #{payment_id} não aprovado: #{status}")
    end

    head :ok
  end

  private

  def activate_premium_for(external_reference)
    return unless external_reference.to_s.start_with?("user_")

    user_id = external_reference.split("_")[1].to_i
    user    = User.find_by(id: user_id)

    unless user
      Rails.logger.warn("[Webhook] User não encontrado para external_reference: #{external_reference}")
      return
    end

    user.update!(premium_until: Time.current + 30.days)
    Rails.logger.info("[Webhook] Premium ativado: user #{user_id} até #{user.premium_until}")
  end
end

class DevController < ApplicationController
  layout "matches"
  before_action :verify_dev_mode
  before_action :authenticate_user!, only: %i[activate_premium expire_premium zero_energy full_energy]

  def login
    user = User.find_or_create_by!(provider: "google_oauth2", uid: "dev_user_001") do |u|
      u.email        = "devuser@gmail.com"
      u.nickname     = "DevUser"
      u.nickname_set = true
    end
    sign_in(user)
    redirect_to root_path, notice: "[DEV] Logado como #{user.email}"
  end

  def activate_premium
    current_user.update!(premium_until: Time.current + 30.days)
    redirect_to root_path, notice: "[DEV] Premium ativado por 30 dias"
  end

  def expire_premium
    current_user.update!(premium_until: 1.day.ago)
    redirect_to root_path, notice: "[DEV] Premium expirado"
  end

  def zero_energy
    current_user.update!(energy: 0, energy_updated_at: Time.current)
    redirect_to root_path, notice: "[DEV] Energia zerada"
  end

  def payment
    @payment_id     = "DEV-000000"
    @qr_code        = "00020126580014br.gov.bcb.pix0136dev-fake-key-torcedor-maluco520400005303986540" \
                      "55802BR5920Torcedor Maluco Dev6009Sao Paulo62070503***6304ABCD"
    @qr_code_base64 = nil
    render "payments/show"
  end

  def full_energy
    current_user.update!(energy: Quiz::Energy::MAX, energy_updated_at: nil)
    redirect_to root_path, notice: "[DEV] Energia cheia"
  end

  private

  def verify_dev_mode
    raise ActionController::RoutingError, "Not Found" unless Rails.env.development?
  end
end

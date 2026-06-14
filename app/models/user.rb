class User < ApplicationRecord
  # OAuth-only: sem senha, sem registro próprio, sem recuperação
  devise :omniauthable, :rememberable, :trackable,
         omniauth_providers: [ :google_oauth2 ]

  # Validações de nickname (só obrigatório após nickname_set)
  with_options if: :nickname_set? do
    validates :nickname,
              presence:   true,
              length:     { minimum: 3, maximum: 18 },
              format:     { with: /\A[\w\-]+\z/, message: "use apenas letras, números, _ ou -" },
              uniqueness: { case_sensitive: false }
  end

  has_many :game_results, dependent: :destroy

  validates :provider, :uid, :email, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # Cria ou recupera usuário a partir do callback OAuth do Google
  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |u|
      u.email      = auth.info.email
      u.avatar_url = auth.info.image
    end
  end

  # --- Energia (regra em Quiz::Energy) ---

  # Energia atual (regenerada sob demanda; não persiste).
  def current_energy(now = Time.current)
    Quiz::Energy.current(stored: energy, updated_at: energy_updated_at, now: now)
  end

  # Instante da próxima recarga, ou nil se cheia.
  def next_recharge_at(now = Time.current)
    Quiz::Energy.next_recharge_at(stored: energy, updated_at: energy_updated_at, now: now)
  end

  # Gancho do M3 (assinante): por enquanto ninguém tem energia ilimitada.
  def unlimited_energy?
    false
  end

  # Debita 1 energia de forma atômica. Retorna true em sucesso, false sem saldo.
  def debit_energy!
    return true if unlimited_energy?

    with_lock do
      current, updated = Quiz::Energy.settle(stored: energy, updated_at: energy_updated_at, now: Time.current)
      if current < 1
        false
      else
        updated = Time.current if current >= Quiz::Energy::MAX
        update!(energy: current - 1, energy_updated_at: updated)
        true
      end
    end
  end
end

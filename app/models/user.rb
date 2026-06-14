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

  validates :provider, :uid, :email, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # Cria ou recupera usuário a partir do callback OAuth do Google
  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |u|
      u.email      = auth.info.email
      u.avatar_url = auth.info.image
    end
  end
end

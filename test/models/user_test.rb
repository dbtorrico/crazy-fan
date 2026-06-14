require "test_helper"

class UserTest < ActiveSupport::TestCase
  def google_auth(uid: "123456", email: "joao@gmail.com", name: "João Silva")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(
        email: email,
        name: name,
        first_name: name.split.first,
        image: "https://example.com/avatar.jpg"
      )
    )
  end

  # --- from_omniauth ---

  test "from_omniauth cria novo usuário quando não existe" do
    auth = google_auth
    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth)
      assert user.persisted?
      assert_equal "google_oauth2", user.provider
      assert_equal "123456", user.uid
      assert_equal "joao@gmail.com", user.email
      assert_equal false, user.nickname_set
    end
  end

  test "from_omniauth retorna usuário existente sem duplicar" do
    auth = google_auth
    User.from_omniauth(auth) # primeira chamada cria
    assert_no_difference "User.count" do
      user = User.from_omniauth(auth) # segunda não duplica
      assert user.persisted?
    end
  end

  # --- validações de nickname ---

  test "nickname válido é aceito" do
    user = users(:joao)
    user.nickname = "Torcedor_1"
    user.nickname_set = true
    assert user.valid?
  end

  test "nickname muito curto é rejeitado" do
    user = users(:joao)
    user.nickname = "ab"
    user.nickname_set = true
    assert_not user.valid?
    assert user.errors[:nickname].any?
  end

  test "nickname com caractere inválido é rejeitado" do
    user = users(:joao)
    user.nickname = "João Silva"  # espaço e acento — inválidos
    user.nickname_set = true
    assert_not user.valid?
    assert user.errors[:nickname].any?
  end
end

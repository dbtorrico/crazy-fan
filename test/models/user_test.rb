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

  # --- energia ---

  test "debit_energy! decrementa a energia e retorna true" do
    user = users(:joao) # energia cheia por default
    assert user.debit_energy!
    assert_equal Quiz::Energy::MAX - 1, user.reload.energy
  end

  test "debit_energy! retorna false e mantém o saldo quando energia é 0" do
    user = users(:joao)
    user.update!(energy: 0, energy_updated_at: Time.current)
    assert_not user.debit_energy!
    assert_equal 0, user.reload.energy
  end

  test "unlimited_energy? é false (gancho do M3)" do
    assert_not users(:joao).unlimited_energy?
  end

  test "current_energy regenera com o passar do tempo" do
    user = users(:joao)
    user.update!(energy: 2, energy_updated_at: Time.current)
    assert_equal 3, user.current_energy(Time.current + Quiz::Energy::RECHARGE_INTERVAL)
  end

  test "current_energy com energy_updated_at nulo é tratado como cheia" do
    user = users(:joao)
    user.update!(energy: 0, energy_updated_at: nil)
    assert_equal Quiz::Energy::MAX, user.current_energy
  end

  test "dois debit_energy! a partir de 1 não deixam o saldo negativo" do
    user = users(:joao)
    user.update!(energy: 1, energy_updated_at: Time.current)
    assert user.debit_energy!
    assert_not user.debit_energy!
    assert_equal 0, user.reload.energy
  end
end

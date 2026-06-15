require "test_helper"

class EnergyGateTest < ActionDispatch::IntegrationTest
  def sign_in_as(user)
    mock_google_auth(uid: user.uid, email: user.email, name: "Teste")
    get "/users/auth/google_oauth2/callback"
    clear_google_mock
  end

  # --- usuário logado ---

  test "logado com energia inicia a partida e debita 1" do
    sign_in_as(users(:joao))
    users(:joao).update!(energy: Quiz::Energy::MAX, energy_updated_at: nil)

    post start_match_path, params: { nickname: "Joao" }

    assert_response :success
    assert session[:match].present?, "deveria ter iniciado a partida"
    assert_equal Quiz::Energy::MAX - 1, users(:joao).reload.energy
  end

  test "logado sem energia vê a tela 'Sem energia' e não inicia partida" do
    sign_in_as(users(:joao))
    users(:joao).update!(energy: 0, energy_updated_at: Time.current)

    post start_match_path, params: { nickname: "Joao" }

    assert_response :success
    assert_nil session[:match], "não deveria iniciar partida sem energia"
    assert_match "Sem energia", response.body
    assert_select "a", text: /ranking/i
  end

  # --- convidado ---

  test "convidado abaixo do limite joga e incrementa o contador da sessão" do
    post start_match_path, params: { nickname: "Visitante" }

    assert_response :success
    assert session[:match].present?
    assert_equal 1, session[:guest_plays]
  end

  test "convidado é bloqueado ao atingir o limite de jogadas da sessão" do
    Quiz::Energy::GUEST_MAX.times do
      post start_match_path, params: { nickname: "Visitante" }
      assert_response :success
    end

    post start_match_path, params: { nickname: "Visitante" }

    assert_response :success
    assert_match "Faça login", response.body
    assert_equal Quiz::Energy::GUEST_MAX, session[:guest_plays], "não deve incrementar quando bloqueado"
  end
end

require "test_helper"

class NicknameFlowTest < ActionDispatch::IntegrationTest
  def sign_in_as(user)
    mock_google_auth(uid: user.uid, email: user.email, name: "Teste")
    get "/users/auth/google_oauth2/callback"
    clear_google_mock
  end

  # --- usuário logado ---

  test "logado inicia a partida usando o nickname do cadastro (sem digitar)" do
    sign_in_as(users(:joao))

    post start_match_path  # sem param nickname

    assert_response :success
    assert_equal users(:joao).nickname, session[:match][:nickname]
  end

  test "home do logado não pede apelido e oferece 'Mudar apelido'" do
    sign_in_as(users(:joao))

    get root_path

    assert_response :success
    assert_select "input[name=?]", "nickname", false, "logado não deve ver campo de apelido"
    assert_match "Mudar apelido", response.body
  end

  # --- convidado ---

  test "convidado informa o apelido uma vez e reutiliza na partida seguinte" do
    post start_match_path, params: { nickname: "Visitante" }
    assert_response :success
    assert_equal "Visitante", session[:nickname]
    assert_equal "Visitante", session[:match][:nickname]

    # segunda partida sem reinformar o apelido
    post start_match_path
    assert_response :success
    assert_equal "Visitante", session[:nickname], "deve manter o apelido da sessão"
    assert_equal "Visitante", session[:match][:nickname]
  end
end

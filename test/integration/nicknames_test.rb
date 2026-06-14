require "test_helper"

class NicknamesTest < ActionDispatch::IntegrationTest
  # Helper para logar como um usuário específico nas integration tests
  def sign_in_as(user)
    mock_google_auth(uid: user.uid, email: user.email, name: "Teste")
    get "/users/auth/google_oauth2/callback"
    clear_google_mock
  end

  test "GET /nickname/new sem login redireciona (Devise)" do
    get new_nickname_path
    assert_response :redirect
    # Devise redireciona convidado — qualquer redirect é OK
    assert_not_equal 200, response.status
  end

  test "GET /nickname/new logado exibe form com sugestão" do
    sign_in_as(users(:maria)) # maria não tem nickname_set
    get new_nickname_path
    assert_response :success
    assert_select "input[name='nickname']"
  end

  test "POST /nickname com nickname válido salva e redireciona para root" do
    sign_in_as(users(:maria))
    post nickname_path, params: { nickname: "MariaFC" }
    assert_redirected_to root_path
    assert users(:maria).reload.nickname_set?
    assert_equal "MariaFC", users(:maria).reload.nickname
  end

  test "POST /nickname com nickname inválido re-renderiza com erro" do
    sign_in_as(users(:maria))
    post nickname_path, params: { nickname: "ab" } # muito curto
    assert_response :unprocessable_entity
    assert_select "p.error, .error, [class*='error']"
  end
end

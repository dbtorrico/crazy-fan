require "test_helper"

class OmniauthCallbacksTest < ActionDispatch::IntegrationTest
  setup { mock_google_auth }
  teardown { clear_google_mock }

  test "novo usuário é criado e redirecionado para tela de nickname" do
    assert_difference "User.count", 1 do
      get "/users/auth/google_oauth2/callback"
    end
    assert_redirected_to new_nickname_path
    assert_not_nil session["warden.user.user.key"], "usuário deve estar logado na sessão"
  end

  test "usuário existente sem nickname é redirecionado para tela de nickname" do
    mock_google_auth(uid: users(:maria).uid, email: users(:maria).email, name: "Maria")
    assert_no_difference "User.count" do
      get "/users/auth/google_oauth2/callback"
    end
    assert_redirected_to new_nickname_path
  end

  test "usuário existente com nickname é redirecionado para root" do
    mock_google_auth(uid: users(:joao).uid, email: users(:joao).email, name: "João")
    assert_no_difference "User.count" do
      get "/users/auth/google_oauth2/callback"
    end
    assert_redirected_to root_path
  end

  test "falha no OAuth redireciona para root com alerta" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
    get "/users/auth/google_oauth2/callback"
    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end
end

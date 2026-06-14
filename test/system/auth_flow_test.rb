require "application_system_test_case"

class AuthFlowTest < ApplicationSystemTestCase
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  # --- Cenário 1: Login → nickname → jogar → resultado salvo ---

  test "usuário faz login, define nickname, joga e vê resultado salvo" do
    # Prepara mock OAuth para novo usuário
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid:  "system_test_uid_001",
      info: { email: "novo@gmail.com", name: "Novo Torcedor", first_name: "Novo", image: nil }
    )

    visit root_path

    # Home: deve ver link de login
    assert_text "Login com Google"

    # Trigger OAuth callback direto (OmniAuth test mode; link é GET mas provider exige POST)
    visit "/users/auth/google_oauth2/callback"

    # Tela de nickname
    assert_current_path new_nickname_path
    assert_selector "input[name='nickname']"

    fill_in "nickname", with: "NovoTorcedor"
    click_on "Entrar no ranking"

    # Volta para root logado
    assert_current_path root_path
    assert_text "NovoTorcedor"

    # Joga uma partida
    click_on "Jogar agora"

    # Responde 5 perguntas
    5.times do
      assert_selector ".opt", minimum: 4
      first(".opt").click
      # Aguarda revelação e auto-avanço
      sleep 2
    end

    # Tela de resultado
    assert_text "pontos"
    assert_text "Resultado salvo no ranking"

    # Verifica GameResult foi criado
    user = User.find_by(uid: "system_test_uid_001")
    assert_not_nil user
    assert user.game_results.any?
  end

  # --- Cenário 2: Convidado vê ranking mas não entra ---

  test "convidado joga, vê aviso de convidado e ranking com CTA" do
    visit root_path
    assert_text "Login com Google"

    click_on "Jogar agora"

    5.times do
      assert_selector ".opt", minimum: 4
      first(".opt").click
      sleep 2
    end

    # Resultado de convidado
    assert_text "jogou como convidado"

    # Visita ranking
    visit ranking_path
    assert_text "Login com Google"  # CTA de login presente
  end

  # --- Cenário 3: Logout ---

  test "usuário logado faz logout e volta a ver botão de login" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid:  users(:joao).uid,
      info: { email: users(:joao).email, name: "João", first_name: "João", image: nil }
    )

    visit "/users/auth/google_oauth2/callback"
    visit root_path

    assert_text users(:joao).nickname

    # Clica em "Sair"
    click_on "Sair"

    # Deslogado — vê link de login
    assert_text "Login com Google"
    assert_no_text "Sair"
  end
end

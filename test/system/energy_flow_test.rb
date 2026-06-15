require "application_system_test_case"

class EnergyFlowTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ]

  setup do
    OmniAuth.config.test_mode = true
    # Perguntas determinísticas para iniciar partidas
    Answer.delete_all
    Question.delete_all
    5.times do |i|
      q = Question.create!(enunciado: "Pergunta #{i + 1}?", tema: "Copa", dificuldade: "facil")
      q.answers.create!(texto: "Certa", correta: true)
      3.times { |j| q.answers.create!(texto: "Errada #{j + 1}", correta: false) }
    end
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  # --- Cenário 1: logado sem energia ---

  test "usuário logado sem energia vê a tela Sem energia ao tentar jogar" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid:  users(:joao).uid,
      info: { email: users(:joao).email, name: "João", first_name: "João", image: nil }
    )

    visit "/users/auth/google_oauth2/callback"
    users(:joao).update!(energy: 0, energy_updated_at: Time.current)

    visit root_path
    assert_text "0/5"                  # indicador de energia zerado

    click_on "Jogar agora"

    assert_text(/sem energia/i)       # CSS aplica uppercase no rótulo
    assert_selector "a", text: /ranking/i
  end

  # --- Cenário 2: convidado atinge o limite de jogadas ---

  test "convidado é convidado a logar ao atingir o limite de jogadas" do
    visit root_path

    Quiz::Energy::GUEST_MAX.times do
      click_on "Jogar agora"
      assert_selector ".opt", minimum: 4   # iniciou a partida
      visit root_path(reset: 1)            # volta à home para jogar de novo
    end

    click_on "Jogar agora"
    assert_text "Faça login com Google para jogar mais"
  end
end

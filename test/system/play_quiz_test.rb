require "application_system_test_case"

class PlayQuizTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ]

  setup do
    Answer.delete_all
    Question.delete_all
    5.times do |i|
      q = Question.create!(enunciado: "Pergunta #{i + 1}?", tema: "Copa", dificuldade: "facil")
      q.answers.create!(texto: "Certa", correta: true)
      3.times { |j| q.answers.create!(texto: "Errada #{j + 1}", correta: false) }
    end
  end

  test "joga partida completa e exibe score correto" do
    visit new_game_path
    click_on "Jogar"

    5.times do |i|
      assert_text "Pergunta #{i + 1} de 5"
      click_on "Certa"
    end

    assert_text "Mandou bem"
    assert_text "5 de 5"
    assert_selector "button", text: "Jogar de novo"
    assert_selector "button", text: "Compartilhar resultado"
  end

  test "timeout conta como erro e avança para próxima pergunta" do
    visit new_game_path
    click_on "Jogar"

    assert_text "Pergunta 1 de 5"

    # Simula o cronômetro zerando
    page.execute_script(
      "document.querySelector('[data-quiz-target=\"form\"]').requestSubmit()"
    )

    assert_text "Pergunta 2 de 5"

    4.times do |i|
      assert_text "Pergunta #{i + 2} de 5"
      click_on "Certa"
    end

    assert_text "Mandou bem"
    assert_text "4 de 5"
  end

  test "jogar de novo reinicia a partida" do
    visit new_game_path
    click_on "Jogar"

    5.times do |i|
      assert_text "Pergunta #{i + 1} de 5"
      click_on "Certa"
    end

    assert_text "Mandou bem"
    click_on "Jogar de novo"

    assert_text "Pergunta 1 de 5"
  end
end

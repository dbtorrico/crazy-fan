require "test_helper"

class HomeScreenTest < ActionDispatch::IntegrationTest
  def make_result(user, played_at: Time.current)
    GameResult.create!(user: user, score: 200, correct_count: 3, questions_count: 5, played_at: played_at)
  end

  test "prova social não aparece quando não há partidas hoje" do
    GameResult.delete_all
    get root_path
    assert_response :success
    assert_no_match /torcedores já jogaram hoje/, response.body
  end

  test "prova social exibe contagem de jogadores distintos do dia" do
    GameResult.delete_all
    make_result(users(:joao))
    make_result(users(:joao))   # mesma pessoa — conta 1
    make_result(users(:maria))  # pessoa diferente — conta 2

    get root_path
    assert_match /2.*torcedores já jogaram hoje|torcedores já jogaram hoje.*2/, response.body
  end

  test "prova social não conta partidas de outros dias" do
    GameResult.delete_all
    make_result(users(:joao), played_at: 2.days.ago)

    get root_path
    assert_no_match /torcedores já jogaram hoje/, response.body
  end
end

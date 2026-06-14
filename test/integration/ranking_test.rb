require "test_helper"

class RankingTest < ActionDispatch::IntegrationTest
  test "GET /ranking sem login retorna 200 e exibe CTA de login" do
    get ranking_path
    assert_response :success
    assert_select "a, button", /[Gg]oogle|[Ll]ogin|[Ee]ntrar/
  end

  test "GET /ranking exibe resultados ordenados por score desc" do
    get ranking_path
    assert_response :success
    # game_results fixture: partida_joao=400pts, partida_maria=200pts
    # joao tem nickname "Joao10"; maria não tem nickname (mostra "Anônimo")
    body = response.body
    pos_joao = body.index(users(:joao).nickname)
    pos_score_400 = body.index("400")
    pos_score_200 = body.index("200")
    assert_not_nil pos_joao, "Deve exibir o nickname de Joao"
    assert pos_score_400 < pos_score_200, "400pts deve aparecer antes de 200pts"
  end
end

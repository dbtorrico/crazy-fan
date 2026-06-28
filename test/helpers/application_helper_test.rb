require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # --- avatar_monogram ---

  test "retorna inicial upcased" do
    assert_equal "F", avatar_monogram("fabim")
    assert_equal "Z", avatar_monogram("Zé do Apito")
  end

  test "fallback para vazio" do
    assert_equal "?", avatar_monogram("")
    assert_equal "?", avatar_monogram(nil)
  end

  test "fallback para Anônimo" do
    assert_equal "?", avatar_monogram("Anônimo")
  end

  test "trata inicial não-latina sem erro" do
    result = avatar_monogram("⚽Craque")
    assert_kind_of String, result
    refute result.empty?
  end

  # --- avatar_color ---

  test "determinístico: mesma seed sempre devolve mesma cor" do
    assert_equal avatar_color("fabim"), avatar_color("fabim")
    assert_equal avatar_color("Zé"),    avatar_color("Zé")
  end

  test "seeds diferentes produzem cores (maioria distintas)" do
    colors = %w[Ana Bob Carlos Dina Ed Fabio Gabi Hana].map { |n| avatar_color(n) }
    assert colors.uniq.size > 1
  end

  test "fallback para seed vazia" do
    assert_equal ApplicationHelper::AVATAR_PALETTE[0], avatar_color("")
    assert_equal ApplicationHelper::AVATAR_PALETTE[0], avatar_color(nil)
  end

  test "retorna cor dentro da paleta" do
    color = avatar_color("qualquer")
    assert_includes ApplicationHelper::AVATAR_PALETTE, color
  end
end

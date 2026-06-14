require "test_helper"

class Quiz::EnergyTest < ActiveSupport::TestCase
  NOW      = Time.utc(2026, 6, 14, 12, 0, 0)
  INTERVAL = Quiz::Energy::RECHARGE_INTERVAL
  MAX      = Quiz::Energy::MAX

  test "cheia: current == MAX e sem próxima recarga" do
    assert_equal MAX, Quiz::Energy.current(stored: MAX, updated_at: NOW - 10.hours, now: NOW)
    assert_nil Quiz::Energy.next_recharge_at(stored: MAX, updated_at: NOW - 10.hours, now: NOW)
  end

  test "regenera 1 após um intervalo" do
    assert_equal 3, Quiz::Energy.current(stored: 2, updated_at: NOW - INTERVAL, now: NOW)
  end

  test "regenera N intervalos respeitando o teto" do
    assert_equal MAX, Quiz::Energy.current(stored: 1, updated_at: NOW - INTERVAL * 10, now: NOW)
  end

  test "menos de um intervalo não regenera" do
    assert_equal 2, Quiz::Energy.current(stored: 2, updated_at: NOW - (INTERVAL - 60), now: NOW)
  end

  test "updated_at nulo é tratado como cheia" do
    assert_equal MAX, Quiz::Energy.current(stored: 0, updated_at: nil, now: NOW)
  end

  test "settle preserva o resto ao avançar o relógio" do
    # 2,5 intervalos desde updated_at, partindo de 0 → +2, relógio avança 2 intervalos
    updated      = NOW - (INTERVAL * 2 + INTERVAL / 2)
    energy, ts   = Quiz::Energy.settle(stored: 0, updated_at: updated, now: NOW)

    assert_equal 2, energy
    assert_equal updated + INTERVAL * 2, ts
    assert_equal ts + INTERVAL, Quiz::Energy.next_recharge_at(stored: 0, updated_at: updated, now: NOW)
  end
end

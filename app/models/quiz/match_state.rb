module Quiz
  # Estado da partida mantido na sessão (sem banco no MVP).
  # PORO serializável — controllers fazem (de)serialização via #to_h / .load.
  class MatchState
    PER_QUESTION_SECONDS = 15
    BASE_POINTS          = 60
    SPEED_BONUS_MAX      = 40
    TOTAL_QUESTIONS      = 5

    attr_reader :nickname, :position, :score, :correct_count,
                :question_ids, :last_choice, :revealed, :deadline_at

    def self.start(nickname:)
      ids = Quiz::Question.sample_ids(TOTAL_QUESTIONS)
      new(
        nickname:     nickname.to_s.strip[0, 18],
        position:     0,
        score:        0,
        correct_count: 0,
        question_ids: ids,
        last_choice:  nil,
        revealed:     false,
        deadline_at:  Time.current + PER_QUESTION_SECONDS
      )
    end

    def self.load(hash)
      return nil if hash.blank?
      h = hash.symbolize_keys
      new(**h.merge(deadline_at: h[:deadline_at] && Time.at(h[:deadline_at].to_f)))
    end

    def initialize(nickname:, position:, score:, correct_count:, question_ids:,
                   last_choice:, revealed:, deadline_at:)
      @nickname      = nickname
      @position      = position
      @score         = score
      @correct_count = correct_count
      @question_ids  = question_ids
      @last_choice   = last_choice
      @revealed      = revealed
      @deadline_at   = deadline_at
    end

    def total            = TOTAL_QUESTIONS
    def current_question = Quiz::Question.find(@question_ids[@position])
    def revealed?        = @revealed
    def finished?        = @position >= TOTAL_QUESTIONS
    def progress_percent = (@position.to_f / TOTAL_QUESTIONS * 100).round
    def screen           = finished? ? :result : :question

    def answer!(choice:, timed_out:)
      return if @revealed
      @last_choice = timed_out ? nil : choice.to_i
      if !timed_out && @last_choice == current_question.correct_index
        seconds_left = [(@deadline_at - Time.current), 0].max
        bonus  = (seconds_left / PER_QUESTION_SECONDS * SPEED_BONUS_MAX).round
        @score += BASE_POINTS + bonus
        @correct_count += 1
      end
      @revealed = true
    end

    def advance!
      @position    += 1
      @revealed     = false
      @last_choice  = nil
      @deadline_at  = Time.current + PER_QUESTION_SECONDS
    end

    def to_h
      { nickname: @nickname, position: @position, score: @score,
        correct_count: @correct_count, question_ids: @question_ids,
        last_choice: @last_choice, revealed: @revealed,
        deadline_at: @deadline_at&.to_f }
    end
  end
end

class MatchesController < ApplicationController
  layout "matches"
  before_action :load_match
  before_action :set_guest_flag

  def show
    if params[:reset] || @match.nil? || @match.finished?
      reset_match
      @match  = nil
      @screen = :home
    else
      @screen = @match.screen
    end
  end

  def start
    return render :show unless enough_energy?

    @match  = Quiz::MatchState.start(nickname: params[:nickname])
    save_match
    @screen = :question
    render :show
  end

  def next_question
    return redirect_to(root_path) if @match.nil?
    @match.advance!
    save_match

    if @match.finished? && user_signed_in?
      GameResult.create(
        user:            current_user,
        score:           @match.score,
        correct_count:   @match.correct_count,
        questions_count: @match.total
      )
    end

    @screen = @match.screen
    render :show
  end

  private

  def set_guest_flag
    @is_guest = !user_signed_in?
  end

  # Aplica a regra de energia antes de iniciar a partida.
  # Logado: debita 1 (bloqueia em :no_energy). Convidado: conta na sessão
  # (bloqueia em :no_energy_guest ao atingir Quiz::Energy::GUEST_MAX).
  def enough_energy?
    if user_signed_in?
      return true if current_user.unlimited_energy? || current_user.debit_energy!

      @screen = :no_energy
      false
    elsif session[:guest_plays].to_i >= Quiz::Energy::GUEST_MAX
      @screen = :no_energy_guest
      false
    else
      session[:guest_plays] = session[:guest_plays].to_i + 1
      true
    end
  end

  def load_match
    @match = Quiz::MatchState.load(session[:match])
  end

  def save_match
    session[:match] = @match.to_h
  end

  def reset_match
    session.delete(:match)
  end
end

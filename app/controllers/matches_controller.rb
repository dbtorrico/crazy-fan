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
    return render :show unless consume_energy!

    @match  = Quiz::MatchState.start(nickname: match_nickname)
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

  # Apelido da partida sem re-solicitar a cada rodada:
  # logado usa o nickname do cadastro; convidado usa/persiste o da sessão.
  def match_nickname
    if user_signed_in?
      current_user.nickname
    else
      session[:nickname] = params[:nickname].presence || session[:nickname]
    end
  end

  # Consome energia para iniciar a partida e retorna true se foi liberada.
  # Tem efeito colateral: logado debita 1 (bloqueia em :no_energy); convidado
  # incrementa o contador da sessão (bloqueia em :no_energy_guest ao atingir
  # Quiz::Energy::GUEST_MAX).
  def consume_energy!
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

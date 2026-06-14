class NicknamesController < ApplicationController
  layout "matches"
  before_action :authenticate_user!

  def new
    @suggested = current_user.email.split("@").first.slice(0, 18).gsub(/[^\w\-]/, "_")
  end

  def create
    if current_user.update(nickname: params[:nickname], nickname_set: true)
      redirect_to root_path, notice: "Nickname salvo! Bem-vindo ao ranking, #{current_user.nickname}!"
    else
      @suggested = params[:nickname]
      render :new, status: :unprocessable_entity
    end
  end
end

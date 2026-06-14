class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in @user, event: :authentication
      if @user.nickname_set?
        redirect_to root_path, notice: "Login realizado com sucesso!"
      else
        redirect_to new_nickname_path
      end
    else
      redirect_to root_path, alert: "Não foi possível autenticar. Tente novamente."
    end
  end

  def failure
    redirect_to root_path, alert: "Autenticação cancelada ou falhou. Tente novamente."
  end
end

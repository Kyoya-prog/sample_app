class SessionsController < ApplicationController
  include SessionsHelper
  def new
  end

  # ログインページからログインするときに呼ばれる　ここで有効化されたユーザーかどうかを確認
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      if user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = "invalid email/password combination"
      render 'new'
    end
  end

  def destroy
    #  複数のタブでログアウトしようとした時に、最初のログアウトでcurrent_userがnilになっているのにも関わらず、もう一度ログアウトしようとすると、userモデルのforgetがエラーになってしまうのでログイン中の場合のみログアウトにする
    log_out if logged_in?
    redirect_to root_path
  end
end

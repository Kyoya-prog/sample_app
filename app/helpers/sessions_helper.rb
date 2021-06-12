module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  # authenticated?の方にも記述したが、複数のブラウザでログアウトしようとすると、エラーが起こる
  # ログアウト時にcurrent_userが実行される。しかし複数ブラウザだと各ブラウザにcookieの情報は残ったままなので、
  # ネストされたif文を通過し、authenticatedが呼ばれ、remember_digestとremember_tokenの比較が BCryptで行われる
  # しかし最初のブラウザのログアウト時にremember_digestはnilになってしまっているのでninにされているのでBCryptにnilを渡したことによるエラーが発生してしまう
  # なのでauthenticated内でremember_digestが存在するかどうかを判定し、なかった場合はメソッド全体でnilを返すようにするgit
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # 渡されたユーザーがカレントユーザーであればtrueを返す
  def current_user?(user)
    user && user == current_user
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end



end

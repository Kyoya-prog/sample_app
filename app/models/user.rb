class User < ApplicationRecord
  attr_accessor :remember_token
  # メールアドレスを保存の前に小文字に統一しておく（DBによっては大文字小文字を区別できないため、indexのuniqueを通り抜ける恐れがある）
  before_save { self.email = email.downcase }
  validates :name, presence: true,length:{maximum: 50}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true,length: {maximum: 255},
            format:{with:VALID_EMAIL_REGEX},
            # case_sensitiveをfalseにしておくことで大文字と小文字を区別できる
            # しかしこれはデータを保存する際にデータベースを探索し同一のものがないかを見ているだけなので
            # 連続保存などではメモリ上に同一のデータが残る恐れがある
            # よってデータベースにインデックスを貼ることで唯一性を担保している
            uniqueness: { case_sensitive: false }
  # これを追加することでUserモデルに仮想的なpassword属性とpassword_confirmation属性が追加される
  has_secure_password
  validates :password,presence:true,length: {minimum: 6}


  # 渡された文字列のハッシュ値を返す(fixture用のpassword_digest生成のため)
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
             BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  #BCriptで暗号化したパスワートダイジェストカラムの値はis_Passwordで認証できる
  # 二つのブラウザがあり、一つのブラウザでログアウトし、もう一つのブラウザでもう一度ログアウトしようとした場合、currentUser実行時に、後者のブラウザでcookieが残ったままなので、rememberdigestが空なのにも関わらずこのメソッドが実行され、Bcryptでエラーになる
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest,nil )
  end
end

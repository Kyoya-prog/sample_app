class User < ApplicationRecord
  has_many :microposts,dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
           foreign_key: "follower_id",
           dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed

  attr_accessor :remember_token, :activation_token, :reset_token
  # メールアドレスを保存の前に小文字に統一しておく（DBによっては大文字小文字を区別できないため、indexのuniqueを通り抜ける恐れがある）
  before_save { self.email = email.downcase }
  before_create{ create_activation_digest }
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
  # nilを許可してもオブジェクト生成時にhas_secure_passwordで検証されるので問題なし
  validates :password,presence:true,length: {minimum: 6},allow_nil: true


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
  def authenticated?(attribute, token)
    digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest,nil )
  end

  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_mail
    UserMailer.account_activation(self).deliver_now
  end

  # パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # パスワード再設定のメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # パスワード再設定用の期限が切れている場合はtrueを返す
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def feed
    Micropost.where("user_id = ?",id)
  end

  #フォローする
  def follow(other_user)
    following << other_user
  end

  # フォロー解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # フォローをしていたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end

  private

  # before_createはユーザーのデータ構造が定義され、データが保存される前に呼び出される
  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

end

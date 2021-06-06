class User < ApplicationRecord
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
end

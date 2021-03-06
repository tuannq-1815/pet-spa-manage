class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token

  has_many :orders, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  before_save {email.downcase!}
  before_create :create_activation_digest

  USER_PARAMS = [:name, :phone, :address, :email, :password, :password_confirmation, :term].freeze
  PASSWORD_PARAMS = [:password, :password_confirmation]
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  NUMBER_REGEX = /\d[0-9]\)*\z/

  validates :name, presence: true, length: {maximum: Settings.max_name_lenght}
  validates :address, presence: true,
    length: {maximum: Settings.max_address_lenght}
  validates :phone, presence: true, length: {is: Settings.phone_lenght},
    format: {with: NUMBER_REGEX}, uniqueness: true
  validates :email, presence: true,
    length: {maximum: Settings.max_email_lenght},
    format: {with: VALID_EMAIL_REGEX}, uniqueness: {case_sensitive: false}
  validates :password, presence: true, allow_nil: true,
    length: {minimum: Settings.min_pass_lenght}

  has_secure_password

  class << self
    def digest string
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    def new_token
      SecureRandom.urlsafe_base64
    end

    def search term
      if term
        where("name LIKE ? OR address LIKE ?", "%#{term}%", "%#{term}%")
      else
        all
      end
    end
  end

  def remember
    self.remember_token = User.new_token
    update remember_digest: User.digest(remember_token)
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update remember_digest: nil
  end

  def activate
    update activated: true, activated_at: Time.zone.now
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update reset_digest: User.digest(reset_token), reset_send_at: Time.zone.now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_send_at < Settings.time_expired.hours.ago
  end

  private

  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end

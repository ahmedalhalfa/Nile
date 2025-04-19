class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  # Methods for password reset
  def generate_password_reset_token
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.now
    save!
  end

  def password_reset_token_valid?
    (reset_password_sent_at + 4.hours) > Time.now
  end

  def reset_password(password)
    self.password = password
    self.reset_password_token = nil
    self.reset_password_sent_at = nil
    save
  end

  private

  def password_required?
    password_digest.nil? || !password.nil?
  end
end

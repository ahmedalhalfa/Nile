class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || "development_secret"
  TOKEN_EXPIRY = 24.hours.to_i

  def self.encode(payload, exp = TOKEN_EXPIRY)
    payload[:exp] = Time.now.to_i + exp
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
    nil
  end
end

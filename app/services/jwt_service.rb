class JwtService
  def self.encode(payload)
    JWT.encode(payload, Devise.secret_key)
  end

  def self.decode(token)
    JWT.decode(token, Devise.secret_key)
  end
end

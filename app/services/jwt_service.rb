class JwtService
  def self.encode(payload)
    JWT.encode(payload, Devise.secret_key)
  end

  def self.decode(token)
    JWT.decode(token, Devise.secret_key)
  end

  def self.extract_user_id(param)
    hash = self.decode(param)[0].symbolize_keys
    hash[:id]
  end
end

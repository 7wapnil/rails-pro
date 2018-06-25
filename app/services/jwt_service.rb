class JwtService
  def self.encode(payload)
    JWT.encode(payload, secret)
  end

  def self.decode(token)
    JWT.decode(token, secret)
  end

  private

  def secret
    'my_secret'
  end
end

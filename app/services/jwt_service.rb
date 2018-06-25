class JwtService
  def self.encode(payload)
    JWT.encode(payload, 'my_secret')
  end

  def self.decode(token)
    JWT.decode(token, 'my_secret')
  end

  def secret
    'my_secret'
  end
end

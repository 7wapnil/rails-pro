class SensitiveDataFilter
  SENSITIVE_DATA_MASK = '[FILTERED]'.freeze

  def self.filter(msg)
    new(msg).filter
  end

  def initialize(msg)
    @msg = msg
  end

  def filter
    filter_password_in_config
    @msg
  end

  private

  def filter_password_in_config
    has_password_logged = @msg.try(:[], :config).try(:[], :password)
    @msg[:config][:password] = SENSITIVE_DATA_MASK if has_password_logged
  end
end

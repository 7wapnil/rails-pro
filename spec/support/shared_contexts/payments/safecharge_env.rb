shared_context 'safecharge_env' do
  let(:env) do
    {
      'SAFECHARGE_SECRET_KEY' => 'secret',
      'SAFECHARGE_HOSTED_PAYMENTS_URL' => 'https://safecharge.com/payment',
      'SAFECHARGE_MERCHANT_ID' => SecureRandom.hex(10),
      'SAFECHARGE_MERCHANT_SITE_ID' => SecureRandom.hex(10),
      'APP_HOST' => 'https://example.com',
      'FRONTEND_URL' => 'https://frontend.example.com'
    }
  end

  before do
    env.each do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end
  end
end

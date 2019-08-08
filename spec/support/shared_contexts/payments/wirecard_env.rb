shared_context 'wirecard_env' do
  let(:env) do
    {
      'WIRECARD_MERCHANT_ACCOUNT_ID' => '1111',
      'WIRECARD_SECRET_KEY' => 'secret',
      'WIRECARD_DEPOSIT_API_ENDPOINT' => 'https://wirecard.example.com',
      'APP_HOST' => 'https://example.com'
    }
  end

  before do
    allow(ENV).to receive(:[])
    env.each do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end
  end
end

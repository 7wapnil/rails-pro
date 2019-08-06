shared_context 'wirecard_env' do
  before do
    allow(ENV)
      .to receive(:[])
      .with('WIRECARD_MERCHANT_ACCOUNT_ID')
      .and_return('1111')

    allow(ENV)
      .to receive(:[])
      .with('WIRECARD_SECRET_KEY')
      .and_return('secret')

    allow(ENV)
      .to receive(:[])
      .with('APP_HOST')
      .and_return('https://example.com')
  end
end

# frozen_string_literal: true

shared_context 'safecharge_env' do
  let(:app_host) { Faker::Internet.url }
  let(:payment_url) { Faker::Internet.url }
  let(:merchant_id) { Faker::Bank.account_number }
  let(:merchant_site_id) { Faker::Vehicle.vin }
  let(:secret_key) { Faker::Vehicle.vin }
  let(:brand_name) { Faker::Restaurant.name }
  let(:web_protocol) { 'https' }
  let(:env) do
    {
      'SAFECHARGE_SECRET_KEY' => secret_key,
      'SAFECHARGE_HOSTED_PAYMENTS_URL' => payment_url,
      'SAFECHARGE_MERCHANT_ID' => merchant_id,
      'SAFECHARGE_MERCHANT_SITE_ID' => merchant_site_id,
      'APP_HOST' => app_host,
      'FRONTEND_URL' => 'https://frontend.example.com',
      'BRAND_NAME' => brand_name,
      'WEB_PROTOCOL' => web_protocol
    }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    env.each do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end
  end
end

describe GraphQL, '#auth_info' do
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { request: request } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:auth_info) { result['data']['authInfo'] }

  let(:query) do
    %(query($login: String!) {
          authInfo(login: $login) {
            isSuspicious
          }
        })
  end

  context 'non-existing user' do
    let(:variables) { Hash[:login, Faker::Internet.email] }

    it { expect(auth_info['isSuspicious']).to be_falsey }
  end

  context 'existing user' do
    let(:failed_attempts) { LoginAttemptable::LOGIN_ATTEMPTS_CAP }
    let(:customer)  { create(:customer, failed_attempts: failed_attempts) }
    let(:variables) { Hash[:login, customer.email] }

    it { expect(auth_info['isSuspicious']).to be_truthy }
  end
end

describe 'GraphQL#AuthInfo' do
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

  let(:query) do
    %(query($login: String!) {
          authInfo(login: $login) {
            login_attempts
            max_login_attempts
          }
        })
  end

  context 'non-existing user' do
    let(:variables) { Hash[:login, Faker::Internet.email] }

    it do
      auth_info = result['data']['authInfo']

      expect(auth_info['login_attempts'])
        .to eq(Account::AuthInfoQuery::FIRST_LOGIN_ATTEMPT)

      expect(auth_info['max_login_attempts'])
        .to eq(LoginAttemptable::LOGIN_ATTEMPTS_CAP)
    end
  end

  context 'existing user' do
    let(:failed_attempts) { rand(2..5) }
    let(:customer)  { create(:customer, failed_attempts: failed_attempts) }
    let(:variables) { Hash[:login, customer.email] }

    it do
      auth_info = result['data']['authInfo']

      expect(auth_info['login_attempts'])
        .to eq(failed_attempts)

      expect(auth_info['max_login_attempts'])
        .to eq(LoginAttemptable::LOGIN_ATTEMPTS_CAP)
    end
  end
end

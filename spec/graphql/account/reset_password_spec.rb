describe GraphQL, '#resetPassword' do
  let(:variables) do
    {
      token: Faker::Internet.email,
      password: 'password',
      confirmation: 'password'
    }
  end

  let(:result) do
    ArcanebetSchema.execute(query,
                            context: {},
                            variables: variables)
  end

  let(:query) do
    %(mutation($token: String!, $password: String!, $confirmation: String!) {
        resetPassword(
          token: $token,
          password: $password,
          confirmation: $confirmation
        )
      })
  end

  before do
    allow(Account::ResetPasswordService).to receive(:call)
  end

  it 'calls Account::ResetPasswordService' do
    result[:data]

    expect(Account::ResetPasswordService).to have_received(:call)
  end
end

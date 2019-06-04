describe GraphQL, '#VerifyPasswordToken' do
  it 'responds to invalid token' do
    query = %(query {
                verifyPasswordToken(token: "FOOBAR") {
                  success
                  message
                }
              })

    response = ArcanebetSchema.execute(query)

    expect(response['data']['verifyPasswordToken'])
      .to eq('success' => false, 'message' => 'Reset password token is invalid')
  end

  it 'responds to expired token' do
    customer = create(:customer, email_verified: true)
    raw_token = Account::SendPasswordResetService.call(customer)

    query = %(query {
                verifyPasswordToken(token: "#{raw_token}") {
                  success
                  message
                }
              })

    Timecop.travel(7.hours.from_now) do
      response = ArcanebetSchema.execute(query)

      expect(response['data']['verifyPasswordToken'])
        .to eq('success' => false, 'message' => 'Reset password token expired')
    end
  end

  it 'responds to valid token' do
    customer = create(:customer, email_verified: true)
    raw_token = Account::SendPasswordResetService.call(customer)

    query = %(query {
                verifyPasswordToken(token: "#{raw_token}") {
                  success
                  message
                }
              })

    response = ArcanebetSchema.execute(query)

    expect(response['data']['verifyPasswordToken'])
      .to eq('success' => true, 'message' => 'Reset password token is valid')
  end
end

describe 'GraphQL#account' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  context 'sign in' do
    let(:query) do
      %(mutation($input: AuthInput!) {
          signIn(input: $input) {
            user { id }
            token
          }
        })
    end

    context 'wrong input' do
      let(:variables) do
        { input: {} }
      end

      it 'should return argument error' do
        expect(result['errors'][0]['message'])
          .to eq('Variable input of type AuthInput! was provided invalid value')
      end
    end

    context 'non-existing user' do
      let(:variables) do
        { input: {
          email: 'unknown@email.com',
          password: '12345'
        } }
      end

      it 'should return empty result' do
        expect(result['data']['signIn'])
          .to be_nil
      end
    end
  end
end

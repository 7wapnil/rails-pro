describe ArcanebetMailer do
  it 'must have default from address' do
    expect(subject.default_params[:from]).to eq('noreply@arcanebet.com')
  end

  it 'must have default subject' do
    expect(subject.default_params[:subject]).to eq('ArcaneBet')
  end
end

describe BettingLimit do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
  it { should belong_to(:title) }

  context 'validation' do
    before do
      FactoryBot.create(:currency, :primary)
    end

    it { should validate_presence_of(:customer) }
  end
end

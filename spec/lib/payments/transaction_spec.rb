describe Payments::Transaction, type: :model do
  it { is_expected.to validate_presence_of(:method) }
  it { is_expected.to validate_presence_of(:customer) }
  it { is_expected.to validate_presence_of(:currency) }
  it { is_expected.to validate_presence_of(:amount) }
  it do
    expect(subject).to validate_numericality_of(:amount)
      .is_greater_than(Payments::Transaction::MIN_AMOUNT)
      .is_less_than(Payments::Transaction::MAX_AMOUNT)
  end

  context 'amount rules' do
    subject do
      described_class.new(method: :credit_card,
                          customer: customer,
                          currency: currency,
                          amount: 100)
    end

    let(:customer) { create(:customer) }
    let(:currency) { create(:currency) }

    it 'validate deposit amount limit' do
      create(:deposit_limit,
             currency: currency,
             customer: customer, value: 10)

      subject.valid?
      expect(subject.errors[:amount])
        .to include('Deposit limit is not available')
    end

    it 'validate deposit attempts limit' do
      subject.valid?
      expect(subject.errors[:amount])
        .to include(I18n.t('errors.messages.deposit_attempts_exceeded'))
    end
  end
end

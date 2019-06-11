describe Forms::WithdrawRequest do
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:password) }
  it { is_expected.to validate_presence_of(:wallet_id) }
  it { is_expected.to validate_presence_of(:payment_method) }

  it { is_expected.to allow_value(100).for(:amount) }
  it { is_expected.not_to allow_value(100.999).for(:amount) }

  it do
    expect(subject)
      .to validate_inclusion_of(:payment_method)
      .in_array(
        ::Payments::SafeCharge::WithdrawalMethods::AVAILABLE_WITHDRAW_MODES.keys
      )
  end

  it do
    expect(subject)
      .to validate_numericality_of(:amount)
      .is_greater_than(0)
  end

  it do
    expect(subject)
      .to validate_numericality_of(:amount)
      .is_less_than(10_000)
  end

  context 'credit card' do
    subject do
      described_class.new(payment_method: 'credit_card',
                          password: 'iamverysecure',
                          customer: create(:customer))
    end

    it 'validates presence of holder name and cvv' do
      subject.valid?
      expect(subject.errors).to include(:holder_name, :last_four_digits)
    end

    it 'validates holder name to be not longer than 100 chars' do
      subject.details = [
        { code: 'holder_name', value: Faker::Lorem.characters(101) }
      ]

      subject.valid?
      expect(subject.errors).to include(:holder_name)
    end

    it 'passes valid holder name ' do
      subject.details = [
        { code: 'holder_name', value: 'Test name' }
      ]

      subject.valid?
      expect(subject.errors).not_to include(:holder_name)
    end

    it 'validates last card number digits value is numerical' do
      subject.details = [
        { code: 'last_four_digits', value: 'notnumber' }
      ]

      subject.valid?
      expect(subject.errors).to include(:last_four_digits)
    end

    it 'validates last card number digits value is 4 digits number' do
      subject.details = [
        { code: 'last_four_digits', value: 123 }
      ]

      subject.valid?
      expect(subject.errors).to include(:last_four_digits)
    end

    it 'passes valid last card number digits value' do
      subject.details = [
        { code: 'last_four_digits', value: 1234 }
      ]

      subject.valid?
      expect(subject.errors).not_to include(:last_four_digits)
    end

    context 'with pending bonus bets' do
      let(:customer) { subject.customer }
      let(:bet) do
        create(:bet,
               customer: customer,
               status: StateMachines::BetStateMachine::ACCEPTED)
      end
      let(:entry_request) do
        create(:entry_request,
               customer: customer,
               origin: bet)
      end
      let!(:balance_entry_request) do
        create(:balance_entry_request,
               entry_request: entry_request,
               kind: Balance::BONUS)
      end

      it 'raises validation error on validate!' do
        expect { subject.validate! }.to(
          raise_error(
            ActiveModel::ValidationError,
            /#{I18n.t('errors.messages.withdrawal.pending_bets_with_bonus')}/
          )
        )
      end
    end
  end
end

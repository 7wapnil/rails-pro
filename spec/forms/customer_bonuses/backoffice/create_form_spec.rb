describe CustomerBonuses::Backoffice::CreateForm, type: :model do
  it { is_expected.to validate_presence_of(:bonus) }
  it { is_expected.to validate_presence_of(:wallet) }
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:initiator) }

  it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

  describe '#submit!' do
    before do
      allow_any_instance_of(Bonuses::ActivationService).to receive(:call)
    end

    it 'runs the validations' do
      expect(subject).to receive(:validate!)

      subject.submit!
    end

    it 'raises when validations fail' do
      expect { subject.submit! }
        .to raise_error ActiveModel::ValidationError
    end

    it 'calls the activation service' do
      allow(subject).to receive(:validate!)
      expect_any_instance_of(Bonuses::ActivationService).to receive(:call)

      subject.submit!
    end
  end
end

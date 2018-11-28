describe DepositLimitsValidation::Service do
  let!(:entry_request) { build(:entry_request) }

  subject { described_class.new(entry_request) }

  it_behaves_like 'callable service'

  describe '.call' do
    context 'without entry requests' do
      let!(:deposit_limit) do
        create(
          :deposit_limit,
          customer: entry_request.customer,
          currency: entry_request.currency
        )
      end

      it 'validates successfully' do
        subject.call

        expect(entry_request.errors.empty?).to be_truthy
      end
    end

    context 'with entry request that reached the limit' do
      let!(:deposit_limit) do
        create(
          :deposit_limit,
          :reached,
          customer: entry_request.customer
        )
      end

      it 'adds :amount field error to entry request' do
        subject.call

        expect(entry_request.errors.empty?).to be_falsey
      end
    end
  end
end

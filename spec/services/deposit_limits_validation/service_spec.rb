describe DepositLimitsValidation::Service do
  subject { described_class.new(entry_request) }

  let!(:entry_request) { build(:entry_request) }

  it_behaves_like 'callable service'

  describe '.call' do
    context 'without entry requests' do
      before do
        create(
          :deposit_limit,
          customer: entry_request.customer,
          currency: entry_request.currency
        )
      end

      it 'validates successfully' do
        subject.call

        expect(entry_request.errors).to be_empty
      end
    end

    context 'with entry request that reached the limit' do
      before do
        create(
          :deposit_limit,
          :reached,
          customer: entry_request.customer
        )
      end

      it 'adds :amount field error to entry request' do
        subject.call

        expect(entry_request.errors).not_to be_empty
      end
    end
  end
end

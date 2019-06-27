describe Payments::Deposit do
  subject { described_class.new(transaction) }

  let(:transaction_attributes) { {} }
  let(:transaction) do
    ::Payments::Transactions::Deposit.new(transaction_attributes)
  end

  describe 'invalid transaction' do
    context 'empty attributes' do
      let(:transaction_attributes) { {} }

      it 'raises empty transaction data' do
        expect { subject.call }
          .to raise_error(Payments::InvalidTransactionError)
      end
    end
  end
end

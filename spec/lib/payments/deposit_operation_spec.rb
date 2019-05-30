describe Payments::Deposit do
  subject { described_class.new(transaction) }

  let(:transaction_attributes) { {} }
  let(:transaction) { Payments::Transaction.new(transaction_attributes) }

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

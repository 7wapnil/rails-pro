# frozen_string_literal: true

describe Wallets::BalanceVerification do
  subject { described_class.call(customer) }

  let!(:negative_balance_label) { create(:label, :negative_balance) }

  let(:customer) { create(:customer) }
  let!(:wallet) do
    create(:wallet, customer: customer,
                    amount: amount,
                    real_money_balance: real_money_balance,
                    bonus_balance: bonus_balance)
  end
  let(:amount) { real_money_balance + bonus_balance }
  let(:real_money_balance) { 0 }
  let(:bonus_balance) { 0 }

  context 'when customer has not negative balance label' do
    before { subject }

    it 'does not add label negative balance to customer' do
      expect(customer.system_labels.negative_balance).to be_nil
    end

    context 'when negative bonus balance' do
      let(:bonus_balance) { -Faker::Number.number(2).to_f }

      it 'adds label negative balance to customer' do
        expect(customer.system_labels.negative_balance).to be_a(Label)
      end
    end

    context 'when negative real money balance' do
      let(:real_money_balance) { -Faker::Number.number(2).to_f }

      it 'adds label negative balance to customer' do
        expect(customer.system_labels.negative_balance).to be_a(Label)
      end
    end
  end

  context 'when customer already has negative balance label' do
    before do
      create(:label_join, labelable: customer, label: negative_balance_label)

      subject
    end

    context 'when balances become zero' do
      it 'removes label negative balance from customer' do
        expect(customer.system_labels.negative_balance).to be_nil
      end
    end

    context 'when balances become positive' do
      let(:real_money_balance) { Faker::Number.number(2).to_f }
      let(:bonus_balance) { Faker::Number.number(2).to_f }

      it 'removes label negative balance from customer' do
        expect(customer.system_labels.negative_balance).to be_nil
      end
    end

    context 'when bonus balance is still negative' do
      let(:bonus_balance) { -Faker::Number.number(2).to_f }

      it 'keeps negative balance label for customer' do
        expect(customer.system_labels.negative_balance).to be_a(Label)
      end
    end

    context 'when real money balance is still negative' do
      let(:real_money_balance) { -Faker::Number.number(2).to_f }

      it 'keeps negative balance label for customer' do
        expect(customer.system_labels.negative_balance).to be_a(Label)
      end
    end
  end

  context 'when another wallet has negative balance' do
    let(:negative_balance) { -10 }
    let!(:another_wallet) do
      create(:wallet, :crypto, customer: customer,
                               amount: negative_balance,
                               real_money_balance: negative_balance,
                               bonus_balance: 0)
    end

    context 'when customer has not negative balance label' do
      before { subject }

      it 'adds label negative balance to customer' do
        expect(customer.system_labels.negative_balance).to be_a(Label)
      end
    end

    context 'when customer already has negative balance label' do
      before do
        create(:label_join, labelable: customer, label: negative_balance_label)

        subject
      end

      it 'does not remove label negative balance from customer' do
        expect(customer.system_labels.negative_balance).to be_a(Label)
      end
    end
  end
end

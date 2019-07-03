# frozen_string_literal: true

DECIMAL_ATTRIBUTES = %i[bonus_wager_amount
                        real_money_wager_amount
                        bonus_payout_amount
                        real_money_payout_amount
                        bonus_deposit_amount
                        real_money_deposit_amount
                        withdraw_amount].freeze
INTEGER_ATTRIBUTES = [:signups_count].freeze
ARRAY_ATTRIBUTES = [:betting_customer_ids].freeze
NOT_IMPLEMENTED_ATTRIBUTE = :xxx

describe Customers::Summaries::Updater do
  subject { described_class.call(summary.day, attribute => value) }

  let!(:summary) { create :customers_summary }

  context 'with decimal attributes' do
    DECIMAL_ATTRIBUTES.each do |attr|
      let(:attribute) { attr }
      let(:value) { rand(0.1..2.0).round(2).to_d }

      it "increments #{attr} correctly" do
        expect { subject }.to(
          change { summary.reload.send(attribute).to_d }.by(value)
        )
      end
    end
  end

  context 'with integer attributes' do
    INTEGER_ATTRIBUTES.each do |attr|
      let(:attribute) { attr }
      let(:value) { rand(1..10) }

      it "increments #{attr} correctly" do
        expect { subject }.to(
          change { summary.reload.send(attribute) }.by(value)
        )
      end
    end
  end

  context 'with array attributes' do
    ARRAY_ATTRIBUTES.each do |attr|
      let(:attribute) { attr }
      let(:value) { rand(0..1000) }
      let(:old_array) { summary.send(attribute) }

      it "appends #{attr} correctly" do
        expect { subject }.to(
          change { summary.reload.send(attribute) }.to(old_array << value)
        )
      end
    end
  end

  context 'with missing attribute' do
    let(:attribute) { NOT_IMPLEMENTED_ATTRIBUTE }
    let(:value) { nil }

    it 'raises NotImplementedError' do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end

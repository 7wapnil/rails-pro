# frozen_string_literal: true

decimal_attributes = %i[bonus_wager_amount
                        real_money_wager_amount
                        bonus_payout_amount
                        real_money_payout_amount
                        bonus_deposit_amount
                        real_money_deposit_amount
                        withdraw_amount].freeze
integer_attributes = %i[signups_count]
array_attributes = %i[betting_customer_ids]
not_implemented_attribute = :xxx

describe Customers::Summaries::Update do
  subject { described_class.call(summary, attribute => value) }

  let!(:summary) { create :customers_summary }

  before { allow(Rails.logger).to receive(:error) }

  context 'with decimal attributes' do
    decimal_attributes.each do |attr|
      let(:attribute) { attr }
      let(:value) { rand(0.1..2.0).round(2).to_d }

      it "increments #{attr} correctly" do
        expect { subject }.to(
          change { summary.reload.send(attribute).to_d }.by(value)
        )
      end

      it 'does not call logger' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end
  end

  context 'with integer attributes' do
    integer_attributes.each do |attr|
      let(:attribute) { attr }
      let(:value) { rand(1..10) }

      it "increments #{attr} correctly" do
        expect { subject }.to(
          change { summary.reload.send(attribute) }.by(value)
        )
      end

      it 'does not call logger' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end
  end

  context 'with array attributes' do
    array_attributes.each do |attr|
      let(:attribute) { attr }
      let(:value) { rand(0..1000) }
      let(:old_array) { summary.send(attribute) }

      it "appends #{attr} correctly" do
        expect { subject }.to(
          change { summary.reload.send(attribute) }.to(old_array << value)
        )
      end

      it 'does not call logger' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end
  end

  context 'with missing attribute' do
    let(:attribute) { not_implemented_attribute }
    let(:value) { nil }

    it 'logs an error' do
      expect(Rails.logger).to receive(:error)
      subject
    end
  end
end

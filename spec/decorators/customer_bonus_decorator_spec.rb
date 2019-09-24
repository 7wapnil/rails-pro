# frozen_string_literal: true

describe CustomerBonusDecorator, type: :decorator do
  subject { customer_bonus.decorate }

  let(:customer_bonus) { build(:customer_bonus, percentage: rand(100.0)) }

  describe '#expires_at' do
    let(:expires_at) { customer_bonus.expires_at }

    it 'returns common value' do
      expect(subject.expires_at).to eq(expires_at)
    end

    it 'returns humanized value' do
      expect(subject.expires_at(human: true))
        .to eq(expires_at.strftime(described_class::EXPIRES_AT_FORMAT))
    end
  end

  describe '#amount' do
    it 'returns zero' do
      expect(subject.amount).to be_zero
    end

    it 'returns humanized zero' do
      expect(subject.amount(human: true))
        .to eq("0.0 #{customer_bonus.currency}")
    end

    context 'with balance_entry' do
      let(:customer_bonus) { create(:customer_bonus, :with_entry) }
      let(:amount) { customer_bonus.entry.bonus_amount }

      it 'returns common value' do
        expect(subject.amount).to eq(amount)
      end

      it 'returns humanized value' do
        expect(subject.amount(human: true))
          .to eq("#{amount} #{customer_bonus.currency}")
      end
    end
  end

  describe '#link_to_entry' do
    it 'shows that entry is not available' do
      expect(subject.link_to_entry).to eq(I18n.t('not_available'))
    end

    context 'with balance_entry' do
      let(:customer_bonus) { create(:customer_bonus, :with_entry) }
      let(:entry) { customer_bonus.entry }
      let(:link_to_entry) do
        helpers.link_to(I18n.t('entities.entry'), entry_path(entry))
      end

      it 'returns link to entry' do
        expect(subject.link_to_entry).to eq(link_to_entry)
      end
    end
  end

  describe '#link_to_customer' do
    let(:customer) { customer_bonus.customer }
    let(:link_to_customer) do
      helpers.link_to(customer.full_name, customer_path(customer))
    end

    it 'returns link to customer' do
      expect(subject.link_to_customer).to eq(link_to_customer)
    end
  end

  describe '#percentage' do
    let(:percentage) { customer_bonus.percentage }

    it 'returns common value' do
      expect(subject.percentage).to eq(percentage)
    end

    it 'returns humanized value' do
      expect(subject.percentage(human: true))
        .to eq(helpers.number_to_percentage(percentage, precision: 0))
    end
  end
end

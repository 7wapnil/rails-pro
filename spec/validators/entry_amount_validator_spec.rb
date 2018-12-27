describe EntryAmountValidator do
  context '#validate' do
    let(:currency) { create(:currency) }
    let(:rule) do
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 10,
             max_amount: 100)
    end
    let(:wallet) { create(:wallet, currency: rule.currency) }

    it 'raises an exception when rule not found' do
      record = build_record(EntryKinds::KINDS.keys.last, 50)

      expect { described_class.new.validate(record) }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it 'doesn\'t add error when amount is in range' do
      record = build_record(rule.kind, 100)

      described_class.new.validate(record)
      expect(record.errors[:amount]).to be_empty
    end

    it 'adds error when amount is out of range' do
      record = build_record(rule.kind, 100.01)

      described_class.new.validate(record)
      expect(record.errors[:amount]).not_to be_empty
    end

    def build_record(kind, amount)
      build(:entry,
            wallet: wallet,
            kind: kind,
            amount: amount)
    end
  end
end

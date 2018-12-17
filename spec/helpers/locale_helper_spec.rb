describe LocaleHelper, type: :helper do
  describe '#safe_date_localize_helper' do
    context 'with nil date' do
      it 'returns nil if no default result provided' do
        expect(helper.safe_date_localize_helper(nil))
          .to be_nil
      end

      it 'returns default result if provided' do
        result = Faker::String.random
        expect(
          helper.safe_date_localize_helper(nil, default_result: result)
        ).to eq(result)
      end
    end

    context 'with not nil date' do
      it 'returns localized date with default format' do
        date = Time.zone.now
        expect(helper.safe_date_localize_helper(date))
          .to eq(I18n.l(date))
      end

      it 'returns localized date with custom format' do
        date = Time.zone.now
        expect(helper.safe_date_localize_helper(date, format: :date_picker))
          .to eq(I18n.l(date, format: :date_picker))
      end
    end
  end
end

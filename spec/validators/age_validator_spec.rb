describe AgeValidator do
  context '#validate' do
    let(:errors_messages) { Hash[date_of_birth: []] }
    let(:message) { I18n.t('errors.messages.age_adult') }

    it 'add error message when age is less than 18' do
      record = double('record', errors: errors_messages,
                                date_of_birth: 17.years.ago)

      described_class.new.validate(record)
      expect(errors_messages[:date_of_birth]).to include(message)
    end

    it "don't add error message when age is greater than 18" do
      record = double('record', errors: errors_messages,
                                date_of_birth: 19.years.ago)

      described_class.new.validate(record)

      expect(errors_messages[:date_of_birth]).to_not include(message)
    end

    it "don't add error message when age is equals 18" do
      record = double('record', errors: errors_messages,
                                date_of_birth: 18.years.ago)

      described_class.new.validate(record)

      expect(errors_messages[:date_of_birth]).to_not include(message)
    end
  end
end

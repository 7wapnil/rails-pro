describe AgeValidator do
  context '#validate' do
    let(:errors_messages) { Hash[date_of_birth: []] }
    let(:message) { I18n.t('errors.messages.age_adult') }
    let(:adult_age) { AgeValidator::ADULT_AGE }

    before do
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    it 'adds error message when age is less than 18' do
      record = instance_double('record',
                               errors: errors_messages,
                               date_of_birth: adult_age.year.ago + 1.day)

      described_class.new.validate(record)
      expect(errors_messages[:date_of_birth]).to include(message)
    end

    it "doesn't add error message when age is greater than adult age" do
      record = instance_double('record',
                               errors: errors_messages,
                               date_of_birth: adult_age.year.ago - 1.day)

      described_class.new.validate(record)

      expect(errors_messages[:date_of_birth]).not_to include(message)
    end

    it "doesn't add error message when age is equals adult age" do
      record = instance_double('record',
                               errors: errors_messages,
                               date_of_birth: adult_age.years.ago)

      described_class.new.validate(record)

      expect(errors_messages[:date_of_birth]).not_to include(message)
    end
  end
end

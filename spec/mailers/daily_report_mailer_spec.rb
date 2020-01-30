# frozen_string_literal: true

describe DailyReportMailer do
  it 'must have default from address' do
    expect(subject.default_params[:from]).to eq('noreply@arcanebet.com')
  end

  it 'must have default subject' do
    expect(subject.default_params[:subject]).to eq('Daily report')
  end

  context 'emails' do
    before do
      allow(ENV)
        .to receive(:fetch)
              .with('DAILY_REPORT_EMAILS', '')
              .and_return(['test@mail.com'])

      allow(ENV)
        .to receive(:fetch)
              .with('DAILY_REPORT_MAIL_TEMPLATE')
              .and_return('')
    end

    it 'sends reset password email' do
      email = described_class.with(data: nil).daily_report_mail

      expect(email.to.first).to eq('test@mail.com')
    end
  end
end

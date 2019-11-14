describe DailyReportMailer do
  it 'must have default from address' do
    expect(subject.default_params[:from]).to eq('noreply@arcanebet.com')
  end

  it 'must have default subject' do
    expect(subject.default_params[:subject]).to eq('Daily Report')
  end

  context 'emails' do
    it 'sends reset password email' do
      query = Reports::Queries::DailyStatsQuery.call
      allow(ENV)
        .to receive(:fetch)
        .with('DAILY_REPORT_EMAILS', '')
        .and_return(['test@mail.com'])

      email =
        described_class.with(data: query).daily_report_mail
      expect(email.to.first).to eq('test@mail.com')
    end
  end
end

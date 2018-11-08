describe PreMatchMarketsClosingWorker do
  it 'calls PreMatchMarketsClosingService' do
    expect(Markets::PreMatchMarketsClosingService).to receive(:call).once

    subject.perform
  end
end

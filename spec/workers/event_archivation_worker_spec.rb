describe EventArchivationWorker do
  it 'copies events to archive' do
    create_list(:event, 10)
    allow(subject).to receive(:archive)

    subject.perform

    expect(subject)
      .to have_received(:archive)
      .exactly(10)
  end
end

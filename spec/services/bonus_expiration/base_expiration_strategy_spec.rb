describe BonusExpiration::BaseExpirationStrategy do
  subject { described_class.new(nil) }

  let(:subject_with_deactivate) do
    described_class.new(nil)
  end

  it 'raise NotImplementedError' do
    expect { subject.call }.to raise_error(NotImplementedError)
  end

  it 'receive #deactivate method' do
    allow(subject_with_deactivate).to receive(:log_deactivation)
    expect(subject_with_deactivate).to receive(:deactivate)

    subject_with_deactivate.call
  end
end

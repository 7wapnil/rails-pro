shared_context 'frozen_time' do
  before { Timecop.freeze }
  after { Timecop.return }
end

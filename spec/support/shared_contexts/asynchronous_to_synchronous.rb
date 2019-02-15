shared_context 'asynchronous to synchronous' do
  before { Sidekiq::Testing.inline! }

  after { Sidekiq::Testing.fake! }
end

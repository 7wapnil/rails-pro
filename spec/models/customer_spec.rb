describe Customer do
  subject(:customer) { described_class.new }

  it { is_expected.to have_one(:address) }
  it { is_expected.to have_many(:wallets) }
  it { is_expected.to have_many(:entry_requests) }
  it { is_expected.to have_many(:labels) }
  it { is_expected.to allow_value(true, false).for(:verified) }
  it { is_expected.to allow_value(true, false).for(:activated) }

  it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:date_of_birth) }
  it { is_expected.to validate_presence_of(:password) }

  it { is_expected.to validate_confirmation_of(:password) }

  it do
    expect(customer).to validate_length_of(:password)
      .is_at_least(6)
      .is_at_most(32)
  end

  it { is_expected.to allow_value('foo@bar.com').for(:email) }
  it { is_expected.not_to allow_value('hello').for(:email) }

  it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  it { is_expected.to act_as_paranoid }

  it_behaves_like 'LoginAttemptable'

  describe 'adult age validation' do
    let(:adult_age) { AgeValidator::ADULT_AGE }

    before do
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    it 'not valid when age is less than adult age' do
      kid_age = adult_age.years.ago + 1.day
      customer = build(:customer, date_of_birth: kid_age)
      customer.valid?
      message = I18n.t('errors.messages.age_adult')

      expect(customer.errors.messages[:date_of_birth]).to include(message)
    end

    it 'valid when age is equals adult age' do
      customer = build(:customer, date_of_birth: adult_age.years.ago)
      customer.valid?
      message = I18n.t('errors.messages.age_adult')

      expect(customer.errors.messages[:date_of_birth]).not_to include(message)
    end
  end

  describe 'account transition' do
    let(:error_message) do
      I18n.t('errors.messages.customer_account_kind_transit')
    end

    it 'from regular' do
      customer = create(:customer, account_kind: :regular)
      customer.account_kind = Customer::TESTING
      customer.password = 'password'
      customer.valid?

      expect(customer.errors.messages[:account_kind]).to be_empty
    end

    it 'can\'t transit customer account kind' do
      customer = create(:customer, account_kind: :staff)
      customer.account_kind = Customer::TESTING
      customer.password = 'password'
      customer.valid?

      expect(customer.errors.messages[:account_kind]).not_to be_empty
    end
  end

  describe 'phone validation' do
    it 'valid when phone number correct' do
      customer = build(:customer, phone: '37258383943')
      customer.valid?

      expect(customer.errors.messages[:phone]).to be_empty
    end

    it 'not valid when phone number incorrect' do
      customer = build(:customer, phone: '999999999999')
      customer.valid?

      expect(customer.errors.messages[:phone]).not_to be_empty
    end
  end

  it 'saves phone number without extra symbols' do
    customer = create(:customer, phone: '+37258383943')

    expect(customer.phone).to eq('37258383943')
  end

  it 'updates tracked fields' do
    customer = create(:customer)
    sign_in_count = customer.sign_in_count
    previous_ip = customer.current_sign_in_ip
    new_ip = Faker::Internet.ip_v4_address
    customer.update_tracked_fields!(OpenStruct.new(remote_ip: new_ip))

    expect(customer.current_sign_in_ip).to eq(new_ip)
    expect(customer.last_sign_in_ip).to eq(previous_ip)
    expect(customer.sign_in_count).to eq(sign_in_count + 1)
    expect(customer.current_sign_in_at).not_to be_nil
    expect(customer.last_sign_in_at).not_to be_nil
  end

  it 'generates activation token on create' do
    customer = create(:customer)
    expect(customer.activation_token).not_to be_nil
  end

  it 'generates email verification token on create' do
    customer = create(:customer)
    expect(customer.email_verification_token).not_to be_nil
  end

  context 'documents' do
    subject { create(:customer) }

    it 'returns history' do
      create_list(:verification_document,
                  3,
                  customer: subject,
                  deleted_at: Time.now)
      create_list(:verification_document, 3, customer: subject)
      expect(subject.documents_history.count).to eq(6)
    end

    it 'returns history by kind' do
      create_list(:verification_document,
                  3,
                  customer: subject,
                  kind: :personal_id)
      create_list(:verification_document,
                  3,
                  customer: subject,
                  kind: :utility_bill)
      expect(subject.documents_history(:personal_id).count).to eq(3)
    end
  end

  describe '#deposit_attempts' do
    include_context 'frozen_time'

    let(:customer) { create(:customer) }

    before do
      EntryRequest.statuses.values.each do |status|
        create(:entry_request,
               :deposit,
               status: status,
               customer: customer,
               created_at: 1.minute.ago)

        create(:entry_request,
               :deposit,
               status: status,
               customer: customer,
               created_at: (24.hours.ago - 1.minute))
      end
    end

    it "returns count of deposits without 'SUCCEEDED' status for last 24hrs" do
      not_succeeded_statuses = EntryRequest
                               .statuses
                               .except(EntryRequest::SUCCEEDED)
      expected_count = not_succeeded_statuses.length

      expect(customer.deposit_attempts).to eq(expected_count)
    end
  end

  describe 'available withdraw methods' do
    let(:customer) { create(:customer) }

    before do
      create(:entry_request,
             customer: customer,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             created_at: Time.new - 7.days)
      create(:entry_request,
             customer: customer,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::SKRILL,
             created_at: Time.new - 6.days)
      create(:entry_request,
             customer: customer,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::PAYSAFECARD,
             created_at: Time.new - 5.days)
      create(:entry_request,
             customer: customer,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             created_at: Time.new - 4.days)
      create(:entry_request,
             customer: customer,
             status: EntryRequest::FAILED,
             mode: EntryRequest::CREDIT_CARD,
             created_at: Time.new - 3.days)
      create(:entry_request,
             customer: customer,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::NETELLER,
             created_at: Time.new - 2.days)
      create(:entry_request,
             customer: customer,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             created_at: Time.new - 1.days)
    end

    it 'returns a list withdraw methods available for customer' do
      available_methods = [EntryRequest::CREDIT_CARD,
                           EntryRequest::NETELLER,
                           EntryRequest::SKRILL]
      expect(customer.available_withdrawal_methods).to eq(available_methods)
    end
  end
end

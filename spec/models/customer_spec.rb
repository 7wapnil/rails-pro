describe Customer do
  it { should have_one(:address) }
  it { should have_many(:wallets) }
  it { should have_many(:entry_requests) }
  it { should have_many(:labels) }
  it { should allow_value(true, false).for(:verified) }
  it { should allow_value(true, false).for(:activated) }

  it { should validate_presence_of(:username) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:date_of_birth) }
  it { should validate_presence_of(:password) }

  it { should validate_confirmation_of(:password) }

  it do
    should validate_length_of(:password)
      .is_at_least(6)
      .is_at_most(32)
  end

  it { should allow_value('foo@bar.com').for(:email) }
  it { should_not allow_value('hello').for(:email) }

  it { should validate_uniqueness_of(:username).case_insensitive }
  it { should validate_uniqueness_of(:email).case_insensitive }

  it { should act_as_paranoid }

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

      expect(customer.errors.messages[:date_of_birth]).to_not include(message)
    end
  end

  describe 'account transition' do
    let(:error_message) do
      I18n.t('errors.messages.customer_account_kind_transit')
    end

    it 'from regular' do
      customer = create(:customer, account_kind: :regular)
      customer.account_kind = :test
      customer.password = 'password'
      expect { customer.save }.to_not raise_error(error_message)
    end

    it 'can\'t transit customer account kind' do
      customer = create(:customer, account_kind: :staff)
      customer.account_kind = :test
      customer.password = 'password'
      expect { customer.save }.to raise_error(error_message)
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

      expect(customer.errors.messages[:phone]).to_not be_empty
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
    expect(customer.activation_token).to_not be_nil
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
end

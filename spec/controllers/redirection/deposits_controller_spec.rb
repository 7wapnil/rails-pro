describe Redirection::DepositsController do
  describe '#initiate' do
    subject { get :initiate }

    it 'does not raise' do
      expect { subject }.not_to raise_error
    end
  end

  describe 'callback endpoints' do
    %i[success error pending back].each do |status_endpoint|
      it 'does not raise' do
        expect { get status_endpoint }.not_to raise_error
      end
    end
  end

  describe '#webhook' do
    subject { get :webhook }

    it 'does not raise' do
      expect { subject }.not_to raise_error
    end
  end
end

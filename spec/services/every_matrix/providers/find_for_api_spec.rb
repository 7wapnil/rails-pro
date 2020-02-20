# frozen_string_literal: true

describe EveryMatrix::Providers::FindForApi do
  subject { described_class.call(slug: query) }

  let(:id) { Faker::Number.number(8).to_i }
  let(:vendor_id) { id }
  let(:content_provider_id) { id + 1 }

  let(:slug) { 'test' }
  let(:vendor_slug) { slug }
  let(:content_provider_slug) { slug }

  let(:vendor_visible) { true }
  let(:content_provider_visible) { true }
  let(:content_provider_as_vendor) { true }

  let!(:vendor) do
    create(:every_matrix_vendor, visible: vendor_visible,
                                 slug: vendor_slug,
                                 id: vendor_id)
  end
  let!(:content_provider) do
    create(:every_matrix_content_provider,
           visible: content_provider_visible,
           as_vendor: content_provider_as_vendor,
           slug: content_provider_slug,
           id: content_provider_id)
  end

  let(:query) { slug }

  xcontext 'by vendor id' do
    let(:query) { vendor.id }

    it 'finds vendor' do
      expect(subject).to eq(vendor)
    end
  end

  xcontext 'by content provider id' do
    let(:query) { content_provider.id }

    it 'finds content_provider' do
      expect(subject).to eq(content_provider)
    end
  end

  context 'by vendor slug' do
    let(:vendor_slug) { 'test-2' }
    let(:query) { vendor.slug }

    it 'finds vendor' do
      expect(subject).to eq(vendor)
    end

    context 'when it is invisible' do
      let(:vendor_visible) { false }

      it 'does not find vendor' do
        expect(subject).to be_nil
      end
    end
  end

  context 'by content provider slug' do
    let(:content_provider_slug) { 'test-2' }
    let(:query) { content_provider.slug }

    it 'finds content_provider' do
      expect(subject).to eq(content_provider)
    end

    context 'when it is invisible' do
      let(:content_provider_visible) { false }

      it 'does not find content provider' do
        expect(subject).to be_nil
      end
    end

    context 'when it is not as vendor' do
      let(:content_provider_as_vendor) { false }

      it 'does not find content provider' do
        expect(subject).to be_nil
      end
    end
  end

  it 'when the same slug finds vendor first' do
    expect(subject).to eq(vendor)
  end

  xcontext 'when the same id' do
    let(:content_provider_id) { id }

    it 'finds vendor first' do
      expect(subject).to eq(vendor)
    end
  end

  context 'when query does not match id or slug' do
    let(:query) { 0 }

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end
end

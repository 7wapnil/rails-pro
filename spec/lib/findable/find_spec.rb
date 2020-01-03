# frozen_string_literal: true

require 'rails_helper'

describe Findable::Find do
  subject { described_class.call(params) }

  let(:value) { Faker::GameOfThrones.character }
  let(:attribute) { :email }
  let(:resource_class) { Customer }
  let(:resource) { create(:customer) }
  let(:params) { full_params }

  let(:full_params) do
    {
      resource_class: resource_class,
      value: resource.id,
      attribute: attribute,
      strict: false
    }
  end

  context 'valid with passed attribute' do
    let(:params) { full_params.merge(value: resource.email) }

    it { expect(subject).to eq(resource) }

    context 'and relation manipulations' do
      let(:joins) { Faker::GameOfThrones.character }
      let(:preload) { Faker::WorldOfWarcraft.name }
      let(:eager_load) { Faker::Superhero.name }

      let(:params) do
        full_params.merge(
          value:      resource.email,
          joins:      joins,
          preload:    preload,
          eager_load: eager_load
        )
      end

      before do
        allow(resource_class)
          .to receive(:joins)
          .with(joins)
          .and_return(resource_class)

        allow(resource_class)
          .to receive(:preload)
          .with(preload)
          .and_return(resource_class)

        allow(resource_class)
          .to receive(:eager_load)
          .with(eager_load)
          .and_return(resource_class)
      end

      it { expect(subject).to eq(resource) }
    end
  end

  context 'valid with default attribute' do
    let(:params) { full_params.except(:attribute) }

    it { expect(subject).to eq(resource) }
  end

  context 'invalid' do
    let(:invalid_class) { User }

    context 'strict' do
      let(:params) do
        full_params
          .except(:resource_class, :strict)
          .merge(resource_class: invalid_class)
      end

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'non-strict' do
      let(:params) do
        full_params
          .except(:resource_class)
          .merge(resource_class: invalid_class)
      end

      it { expect(subject).to be_nil }
    end

    context 'with invalid resource class' do
      let(:resource_class) { "#{Faker::Lorem.word.capitalize}aa" }
      let(:message) do
        "You haven't defined such resource class: `#{resource_class}`."
      end

      it { expect { subject }.to raise_error(NameError, message) }
    end
  end
end

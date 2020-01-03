# frozen_string_literal: true

require 'rails_helper'

describe Findable::Finder do
  subject { described_class.call(params) }

  let(:controller) { ApplicationController.new }
  let(:value) { Faker::Internet.email }
  let(:controller_params) { { entity: { nested: { email: value } } } }
  let(:resource_name) { :user }
  let(:resource_class) { Customer }
  let(:by) { %i[entity nested email] }
  let(:attribute) { :email }
  let(:strict) { false }
  let(:fallback_parameter) { Faker::GameOfThrones.character }
  let(:fallback_value_parameter) { Faker::GameOfThrones.character }

  let(:full_params) do
    {
      controller:     controller,
      resource_name:  resource_name,
      class:          resource_class,
      by:             by,
      attribute:      attribute,
      strict:         strict,
      fallback:       fallback_parameter,
      fallback_value: fallback_value_parameter
    }
  end

  before { controller.params = controller_params }

  context 'with `resource_class` passed ' do
    context 'explicit' do
      let(:params) { full_params.slice(:controller, :resource_name, :class) }

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(resource_class: resource_class))

        subject
      end
    end

    context 'implicit' do
      let(:implicit_resource_class) { User.name }
      let(:params) { full_params.slice(:controller, :resource_name) }

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(resource_class: implicit_resource_class))

        subject
      end
    end
  end

  context 'with `strict` passed' do
    context 'when fallback passed' do
      let(:params) do
        full_params
          .slice(:controller, :resource_name, :fallback)
          .merge(strict: true)
      end

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(strict: false))

        subject
      end
    end

    context 'not passed' do
      let(:params) { full_params.slice(:controller, :resource_name) }

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(strict: true))

        subject
      end
    end

    context 'disabled' do
      let(:params) do
        full_params.slice(:controller, :resource_name).merge(strict: false)
      end

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(strict: false))

        subject
      end
    end
  end

  context 'with `by` passed' do
    context 'when `fallback_value` passed but value was found' do
      let(:params) do
        full_params.slice(:controller, :resource_name, :by, :fallback_value)
      end

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(value: value))

        subject
      end
    end

    context "when `fallback_value` passed and value wasn't found" do
      let(:params) do
        full_params
          .slice(:controller, :resource_name, :fallback_value)
          .merge(by: :email)
      end

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(value: fallback_value_parameter))

        subject
      end
    end

    context 'default' do
      let(:current_user) { create(:customer) }
      let(:id) { current_user.id }
      let(:params) { full_params.slice(:controller, :resource_name) }

      before { controller.params = Hash[:id, id] }

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(value: id))

        subject
      end
    end
  end

  context 'with `attribute` passed' do
    context 'explicitly' do
      let(:params) do
        full_params.slice(:controller, :resource_name, :attribute)
      end

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(attribute: attribute))

        subject
      end
    end

    context 'default' do
      let(:default_attribute) { :id }
      let(:params) { full_params.slice(:controller, :resource_name) }

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(attribute: default_attribute))

        subject
      end
    end
  end

  context 'with `fallback_value` passed' do
    context 'as value' do
      let(:params) do
        full_params.slice(:controller, :resource_name, :fallback_value)
      end

      it do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(value: fallback_value_parameter))

        subject
      end
    end

    context 'as proc' do
      let(:params) do
        full_params
          .slice(:controller, :resource_name)
          .merge(fallback_value: -> { 2 + 2 })
      end

      it do
        expect(Findable::Find).to receive(:call).with(hash_including(value: 4))

        subject
      end
    end

    context 'as method' do
      let(:method_name) { Faker::Lorem.word.to_sym }
      let(:value) { Faker::Bank.name }
      let(:params) do
        full_params
          .slice(:controller, :resource_name)
          .merge(fallback_value: method_name)
      end

      before do
        allow(controller)
          .to receive(:send)
          .with(method_name)
          .and_return(value)
      end

      it 'calls finder service' do
        expect(Findable::Find)
          .to receive(:call)
          .with(hash_including(value: value))

        subject
      end
    end
  end

  context 'with `fallback` passed' do
    before { allow_any_instance_of(described_class).to receive(:resource) }

    context 'as value' do
      let(:params) { full_params.slice(:controller, :resource_name, :fallback) }

      it { expect(subject).to eq(fallback_parameter) }
    end

    context 'as proc' do
      let(:params) do
        full_params
          .slice(:controller, :resource_name)
          .merge(fallback: -> { 2 + 2 })
      end

      it { expect(subject).to eq(4) }
    end

    context 'as method' do
      let(:method_name) { Faker::Lorem.word.to_sym }
      let(:value) { Faker::Bank.name }

      let(:params) do
        full_params
          .slice(:controller, :resource_name)
          .merge(fallback: method_name)
      end

      before do
        allow(controller)
          .to receive(:send)
          .with(method_name)
          .and_return(value)
      end

      it { expect(subject).to eq(value) }
    end
  end

  context 'with relation-based options passed' do
    let(:params) do
      full_params
        .merge(joins: :joins, preload: :preload, eager_load: :eager_load)
    end

    it do
      expect(Findable::Find)
        .to receive(:call)
        .with(
          hash_including(
            joins: :joins,
            preload: :preload,
            eager_load: :eager_load
          )
        )

      subject
    end
  end
end

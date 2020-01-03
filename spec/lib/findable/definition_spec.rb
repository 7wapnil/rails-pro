# frozen_string_literal: true

require 'rails_helper'

describe Findable::Definition do
  subject { described_class.call(params) }

  let(:controller_class) { ApplicationController }
  let(:resource_name) { Faker::Lorem.word }
  let(:resource) { build_stubbed(:customer) }
  let(:finder_name) do
    "find_#{resource_name}#{only_suffix}#{except_suffix}!".to_sym
  end
  let(:only_suffix) { '_only_show' }
  let(:except_suffix) { '_except_index' }
  let(:only) { %i[show] }
  let(:except) { %i[index] }

  let(:params) do
    {
      controller:    controller_class,
      resource_name: resource_name,
      only:          only,
      except:        except,
      by:            resource_name,
      joins:         :joins,
      preload:       :preload,
      eager_load:    :eager_load
    }
  end

  context 'add callback' do
    before { allow(controller_class).to receive(:define_method) }

    context 'to all actions' do
      let(:only) { nil }
      let(:only_suffix) { nil }
      let(:except) { nil }
      let(:except_suffix) { nil }

      it do
        expect(controller_class)
          .to receive(:before_action)
          .with(finder_name, {})

        subject
      end
    end

    context 'with defined restrictions' do
      it do
        expect(controller_class)
          .to receive(:before_action)
          .with(finder_name, only: only, except: except)

        subject
      end
    end
  end

  context 'define finder method' do
    let(:controller) { controller_class.new }
    let(:found_resource) do
      controller.instance_variable_get("@#{resource_name}")
    end
    let(:define_finder) { controller.send(finder_name) }

    let(:arguments) do
      {
        controller:    controller,
        resource_name: resource_name,
        by:            resource_name,
        joins:         :joins,
        preload:       :preload,
        eager_load:    :eager_load
      }
    end

    before do
      allow(controller_class).to receive(:before_action)
      allow(Findable::Finder)
        .to receive(:call)
        .with(arguments)
        .and_return(resource)

      subject

      define_finder
    end

    it { expect(found_resource).to eq(resource) }
  end
end

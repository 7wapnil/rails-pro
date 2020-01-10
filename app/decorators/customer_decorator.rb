# frozen_string_literal: true

class CustomerDecorator < ApplicationDecorator
  decorates_association :labels, with: LabelDecorator
  decorates_association :system_labels, with: LabelDecorator
end

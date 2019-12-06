# frozen_string_literal: true

module Importable
  extend ActiveSupport::Concern

  included do
    class_attribute :conflict_updatable_cols
    class_attribute :conflict_target_attributes
  end

  class_methods do
    def create_or_update_on_duplicate(record, validate: true, recursive: true)
      target = conflict_target_attributes
      columns = conflict_updatable_cols || []
      raise ArgumentError, 'Conflict target not found' unless target

      import([record].flatten,
             validate: validate,
             recursive: recursive,
             on_duplicate_key_update: {
               conflict_target: target,
               columns: columns
             })
    end

    def create_or_ignore_on_duplicate(record, validate: true)
      import([record],
             validate: validate,
             on_duplicate_key_ignore: true)
    end

    def conflict_updatable(*columns)
      self.conflict_updatable_cols = columns
    end

    def conflict_target(*columns)
      self.conflict_target_attributes = columns
    end
  end
end

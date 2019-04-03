module Titles
  class CollectHashByKind < ApplicationService
    def call
      Hash[
        Title.kinds.keys.map do |kind|
          [kind, Title.send(kind).order(:position)]
        end
      ]
    end
  end
end

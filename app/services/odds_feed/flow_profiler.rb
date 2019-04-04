module OddsFeed
  class EmptyMessageProfiler
    def trace_profiler_event(_event_name); end

    def dump; end

    def to_h
      {}
    end
  end

  module FlowProfiler
    extend ActiveSupport::Concern

    def create_flow_profiler(serialized_attributes: nil, attributes: nil)
      destroy_flow_profiler

      default_attributes =
        if serialized_attributes
          OddsFeed::MessageProfiler.deserialize(serialized_attributes).to_h
        else
          OddsFeed::MessageProfiler.new(attributes).to_h
        end
      profiler_attributes_storage_set(default_attributes)
    end

    def update_flow_profiler_property(properties = {})
      return if flow_profiler.is_a? EmptyMessageProfiler

      modified_profiler =
        OddsFeed::MessageProfiler.new(flow_profiler.to_h.merge(properties))
      profiler_attributes_storage_set(modified_profiler.to_h)
    end

    def destroy_flow_profiler
      profiler_attributes_storage_destroy
    end

    def flow_profiler
      return empty_profiler unless profiler_attributes_storage

      OddsFeed::MessageProfiler.new(profiler_attributes_storage)
    end

    private

    def empty_profiler
      EmptyMessageProfiler.new
    end

    # TODO: Extract internals to OddsFeed::ProfilerAttributesStorage

    def profiler_attributes_storage_key
      :flow_profiler
    end

    def profiler_attributes_storage_destroy
      Thread.current.thread_variable_set(profiler_attributes_storage_key, nil)
    end

    def profiler_attributes_storage_set(value)
      Thread.current[profiler_attributes_storage_key] = value
    end

    def profiler_attributes_storage
      Thread.current[profiler_attributes_storage_key]
    end
  end
end

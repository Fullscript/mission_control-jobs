# TODO: These should be moved to +ActiveJob::Core+ and related concerns
# when upstreamed.
module ActiveJob::Executing
  extend ActiveSupport::Concern

  included do
    attr_accessor :last_execution_error
    attr_reader :serialized_arguments
    thread_cattr_accessor :_current_queue_adapter
  end

  class_methods do
    def queue_adapter
      current_queue_adapter || super
    end

    def current_queue_adapter=(adapter)
      self._current_queue_adapter = adapter
      adapter.try(:activate)
    end

    def current_queue_adapter
      _current_queue_adapter
    end
  end

  def retry
    ActiveJob.jobs.failed.retry_job(self)
  end
end

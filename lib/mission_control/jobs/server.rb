class MissionControl::Jobs::Server
  include MissionControl::Jobs::IdentifiedByName

  attr_reader :name, :queue_adapter

  def initialize(name:, queue_adapter:)
    super(name: name)
    @queue_adapter = queue_adapter
  end

  def activate
    ActiveJob::Base.current_queue_adapter = queue_adapter
  end
end

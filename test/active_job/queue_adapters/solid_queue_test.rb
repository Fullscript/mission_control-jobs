require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting
  include DispatchJobs

  setup do
    SolidQueue.logger = ActiveSupport::Logger.new(nil)
  end

  test "find_job returns failed job when multiple jobs share same active_job_id" do
    failed_job = FailingJob.perform_later(42)
    perform_enqueued_jobs

    original_job = SolidQueue::Job.find_by(active_job_id: failed_job.job_id)
    assert original_job.failed?

    newer_job = SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "FailingJob",
      active_job_id: failed_job.job_id,
      arguments: { job_class: "FailingJob", arguments: [ 42 ] },
      finished_at: Time.current
    )

    assert newer_job.id > original_job.id
    assert newer_job.finished?
    assert_not newer_job.failed?

    found_job = ActiveJob.jobs.failed.find_by_id(failed_job.job_id)

    assert_not_nil found_job
    assert_equal :failed, found_job.status
  end

  test "find_job returns nil when no job matches status filter" do
    pending_job = DummyJob.perform_later

    found_job = ActiveJob.jobs.failed.find_by_id(pending_job.job_id)

    assert_nil found_job
  end

  private
    def queue_adapter
      :solid_queue
    end

    def perform_enqueued_jobs
      worker = SolidQueue::Worker.new(queues: "*", threads: 1, polling_interval: 0.01)
      worker.mode = :inline
      worker.start
    end
end

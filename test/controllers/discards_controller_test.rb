require "test_helper"

class MissionControl::Jobs::DiscardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @worker.start
    FailingJob.queue_as :default
  end

  test "discards failed job when status param is provided" do
    failed_job = FailingJob.perform_later(42)
    perform_enqueued_jobs_async

    assert_equal 1, ActiveJob.jobs.failed.count

    assert_difference -> { ActiveJob.jobs.failed.count }, -1 do
      post mission_control_jobs.application_job_discard_url(@application, failed_job.job_id, status: :failed)
    end

    assert_redirected_to mission_control_jobs.application_jobs_url(@application, :failed)
    assert_equal "Discarded job with id #{failed_job.job_id}", flash[:notice]
  end

  test "discards correct failed job when multiple jobs share same active_job_id" do
    failed_job = FailingJob.perform_later(42)
    perform_enqueued_jobs_async

    original_solid_queue_job = SolidQueue::Job.find_by(active_job_id: failed_job.job_id)
    assert original_solid_queue_job.failed?

    newer_job = SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "FailingJob",
      active_job_id: failed_job.job_id,
      arguments: { job_class: "FailingJob", arguments: [ 42 ] },
      finished_at: Time.current
    )

    assert newer_job.id > original_solid_queue_job.id
    assert newer_job.finished?
    assert_not newer_job.failed?

    assert_equal 1, ActiveJob.jobs.failed.count
    assert_equal 1, ActiveJob.jobs.finished.count

    post mission_control_jobs.application_job_discard_url(@application, failed_job.job_id, status: :failed)

    assert_equal 0, ActiveJob.jobs.failed.count
    assert_equal 1, ActiveJob.jobs.finished.count
  end

  test "returns job not found when job with status does not exist" do
    failed_job = FailingJob.perform_later(42)
    perform_enqueued_jobs_async

    failed_job_record = SolidQueue::Job.find_by(active_job_id: failed_job.job_id)
    failed_job_record.failed_execution.destroy!

    post mission_control_jobs.application_job_discard_url(@application, failed_job.job_id, status: :failed)

    assert_redirected_to mission_control_jobs.application_jobs_path(@application, :failed)
    assert_match /not found/i, flash[:alert]
  end
end

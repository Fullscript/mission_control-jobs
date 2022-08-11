module ActiveJob::QueueAdapters::AdapterTesting::RetryJobs
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  test "retrying jobs raises an error for jobs that are not in a failed state" do
    10.times { DummyJob.perform_later }
    assert_raises ActiveJob::Errors::InvalidOperation do
      ActiveJob.jobs.retry_all
    end
  end

  test "retry all failed jobs" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    failed_jobs = ActiveJob.jobs.failed
    assert_not_empty failed_jobs
    failed_jobs.retry_all

    assert_empty failed_jobs
  end

  test "retry all failed withing a given page" do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    assert_equal 10, ActiveJob.jobs.failed.count

    failed_jobs = ActiveJob.jobs.failed.offset(2).limit(3)
    failed_jobs.retry_all

    assert_equal 7, ActiveJob.jobs.failed.count

    [ 0, 1, 5, 6, 7, 8, 9 ].each.with_index do |expected_argument, index|
      assert_equal [ expected_argument ], ActiveJob.jobs.failed[index].serialized_arguments
    end
  end

  test "retry all failed of a given kind" do
    10.times { |index| FailingJob.perform_later(index) }
    5.times { |index| FailingReloadedJob.perform_later(index) }
    perform_enqueued_jobs

    assert_equal 15, ActiveJob.jobs.failed.count

    failed_jobs = ActiveJob.jobs.failed.where(job_class: "FailingReloadedJob")
    failed_jobs.retry_all

    assert_equal 10, ActiveJob.jobs.failed.count

    assert_not ActiveJob.jobs.failed.find { |job| job.is_a?(FailingReloadedJob) }
  end

  test "retry a single failed job" do
    FailingJob.perform_later
    perform_enqueued_jobs

    assert_not_empty ActiveJob.jobs.failed

    failed_job = ActiveJob.jobs.failed.last
    failed_job.retry

    assert_empty ActiveJob.jobs.failed
  end

  test "retrying a single job fails if the job does not exist" do
    FailingJob.perform_later
    perform_enqueued_jobs
    failed_job = ActiveJob.jobs.failed.last
    delete_all_jobs

    assert_raise ActiveJob::Errors::JobNotFoundError do
      failed_job.retry
    end
  end
end

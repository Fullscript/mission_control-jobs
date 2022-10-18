require_relative "../application_system_test_case"

class RetryJobsTest < ApplicationSystemTestCase
  setup do
    5.times { |index| FailingJob.perform_later(index) }
    5.times { |index| FailingReloadedJob.perform_later(5 + index) }
    perform_enqueued_jobs

    visit failed_jobs_path
  end

  test "retry all failed jobs" do
    assert_equal 10, job_row_elements.length

    click_on "Retry all"

    assert_text "Retried 10 jobs"
    assert_empty job_row_elements
  end

  test "retry a single job" do
    assert_equal 10, job_row_elements.length
    expected_job_id = ApplicationJob.jobs.failed[2].job_id

    within_job_row "2" do
      click_on "Retry"
    end

    assert_text "Retried job with id #{expected_job_id}"

    assert_equal 9, job_row_elements.length
  end

  test "retry a selection of filtered jobs" do
    assert_equal 10, job_row_elements.length

    fill_in "filter[job_class]", with: "FailingJob"
    assert_text /5 jobs selected/i

    click_on "Retry selection"
    assert_text /retried 5 jobs/i
    assert_equal 5, job_row_elements.length
  end

  test "retry a job from its details screen" do
    assert_equal 10, job_row_elements.length
    failed_job = ApplicationJob.jobs.failed[2]
    visit failed_job_path(failed_job.job_id)

    click_on "Retry"

    assert_text "Retried job with id #{failed_job.job_id}"
    assert_equal 9, job_row_elements.length
  end
end

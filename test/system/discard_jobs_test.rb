require_relative "../application_system_test_case"

class DiscardJobsTest < ApplicationSystemTestCase
  setup do
    5.times { |index| FailingJob.perform_later(index) }
    5.times { |index| FailingReloadedJob.perform_later(5 + index) }
    perform_enqueued_jobs

    visit jobs_path(:failed)
  end

  test "discard all failed jobs" do
    assert_equal 10, job_row_elements.length

    accept_confirm do
      click_on "Discard all"
    end

    assert_text "Discarded 10 jobs"
    assert_empty job_row_elements
  end

  test "discard a single job" do
    assert_equal 10, job_row_elements.length
    expected_job_id = ApplicationJob.jobs.failed[2].job_id

    within_job_row "2" do
      accept_confirm do
        click_on "Discard"
      end
    end

    assert_text "Discarded job with id #{expected_job_id}"

    assert_equal 9, job_row_elements.length
  end

  test "retry a selection of filtered jobs" do
    assert_equal 10, job_row_elements.length

    fill_in "filter[job_class_name]", with: "FailingJob"
    assert_text /5 jobs selected/i

    accept_confirm do
      click_on "Discard selection"
    end

    assert_text /discarded 5 jobs/i
    assert_equal 5, job_row_elements.length
  end

  test "discard a job from its details screen" do
    assert_equal 10, job_row_elements.length
    failed_job = ApplicationJob.jobs.failed[2]
    visit job_path(failed_job.job_id)

    accept_confirm do
      click_on "Discard"
    end

    assert_text "Discarded job with id #{failed_job.job_id}"
    assert_equal 9, job_row_elements.length
  end
end

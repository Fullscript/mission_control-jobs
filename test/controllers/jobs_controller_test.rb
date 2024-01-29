require "test_helper"

class MissionControl::Jobs::JobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DummyJob.queue_as :queue_1
    @job = DummyJob.perform_later(42)
  end

  test "get job details" do
    get mission_control_jobs.application_job_url(@application, @job.job_id)
    assert_response :ok

    assert_includes response.body, @job.job_id
    assert_includes response.body, "queue_1"

    get mission_control_jobs.application_job_url(@application, @job.job_id, filter: { queue_name: "queue_1" })
    assert_response :ok

    assert_includes response.body, @job.job_id
    assert_includes response.body, "queue_1"
  end

  test "redirect to queue when job doesn't exist" do
    get mission_control_jobs.application_job_url(@application, @job.job_id + "0", filter: { queue_name: "queue_1" })
    assert_redirected_to mission_control_jobs.application_queue_path(@application, :queue_1)
  end
end

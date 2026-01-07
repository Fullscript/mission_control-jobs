class MissionControl::Jobs::DiscardsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped

  def create
    @job.discard
    redirect_to redirect_location, notice: "Discarded job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      if params[:status].present?
        ActiveJob.jobs.with_status(params[:status])
      else
        ActiveJob.jobs
      end
    end

    def redirect_location
      status = @job.status.presence_in(supported_job_statuses) || :failed
      application_jobs_url(@application, status)
    end
end

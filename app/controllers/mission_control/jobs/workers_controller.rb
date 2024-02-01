class MissionControl::Jobs::WorkersController < MissionControl::Jobs::ApplicationController
  before_action :ensure_exposed_workers

  def index
    @workers_page = MissionControl::Jobs::Workers::Page.new(workers, page: params[:page].to_i)
    @workers_count = @workers_page.total_count
  end

  def show
    @worker = current_server.find_worker(params[:id])
  end

  private
    def ensure_exposed_workers
      unless workers_exposed?
        redirect_to root_url, alert: "This server doesn't expose workers"
      end
    end

  def current_server
    MissionControl::Jobs::Current.server
  end

  def workers
    current_server.workers.sort_by { |worker| -worker.jobs.count }
  end

end

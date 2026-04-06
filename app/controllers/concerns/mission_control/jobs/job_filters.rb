module MissionControl::Jobs::JobFilters
  extend ActiveSupport::Concern

  included do
    before_action :set_filters

    helper_method :active_filters?, :jobs_filter_param
  end

  private
    def set_filters
      if filtering_disabled?
        @job_filters = {}
      else
        @job_filters = {
          job_class_name: finished_status? ? nil : params.dig(:filter, :job_class_name).to_s.strip.presence,
          queue_name: params.dig(:filter, :queue_name).to_s.strip.presence,
          finished_at: finished_at_range_params
        }.compact
      end
    end

    def active_filters?
      @job_filters.any?
    end

    def jobs_filter_param
      if @job_filters&.any?
        { filter: @job_filters }
      else
        {}
      end
    end

    def finished_at_range_params
      range_start, range_end = params.dig(:filter, :finished_at_start), params.dig(:filter, :finished_at_end)
      if range_start || range_end
        (parse_with_time_zone(range_start)..parse_with_time_zone(range_end))
      end
    end

    def parse_with_time_zone(date)
      Time.zone.parse(date) if date.present?
    end

    def filtering_disabled?
      %w[in_progress blocked scheduled].include?(params[:status])
    end

    def finished_status?
      params[:status] == "finished"
    end
end

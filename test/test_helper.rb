# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

require_relative "active_job/queue_adapters/adapter_testing"
Dir[File.join(__dir__, "support", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "active_job", "queue_adapters", "adapter_testing", "*.rb")].each { |file| require file }

class ActiveSupport::TestCase
  include JobQueuesHelper

  parallelize workers: :number_of_processors

  teardown { delete_adapters_data }

  private
    def delete_adapters_data
      delete_resque_data
    end

    def delete_resque_data
      redis = Resque.redis
      if redis.try(:namespace)
        all_keys = redis.keys("*")
        redis.del all_keys if all_keys.any?
      else
        redis.flushdb
      end
    end
end

require 'sidekiq'
require 'sidekiq/api'

require 'sidekiq/debounce/version'

module Sidekiq
  module Debounce
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      DEFAULT_DEBOUNCE_FOR = 5 * 60 # 5.minutes
      DEFAULT_DEBOUNCE_BY = -> (job_args) { 0 }

      def debounce(*args)
        sidekiq_options["debounce"] ||= {}

        debounce_for = sidekiq_options["debounce"][:time] || DEFAULT_DEBOUNCE_FOR
        debounce_by = sidekiq_options["debounce"][:by] || DEFAULT_DEBOUNCE_BY
        debounce_by_value = debounce_by.call(args)

        ss = Sidekiq::ScheduledSet.new
        jobs = ss.select do |job|
          job.klass == self.to_s &&
          debounce_by.call(job.args[0][0]) == debounce_by_value
        end

        time_from_now = Time.now + debounce_for
        jobs_to_group = []

        jobs.each do |job|
          if job.at > Time.now && job.at < time_from_now
            jobs_to_group += job.args[0]
            job.delete
          end
        end

        jobs_to_group << args

        perform_in(debounce_for, jobs_to_group)
      end
    end
  end
end

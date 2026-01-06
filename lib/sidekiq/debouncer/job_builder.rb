# frozen_string_literal: true

module Sidekiq
  module Debouncer
    module JobBuilder
      extend Sidekiq::JobUtil

      def self.build(job_args, debounce_key)
        base_job = nil
        final_args = job_args.map do |elem|
          if elem.start_with?("{")
            base_job = Sidekiq.load_json(elem)
            base_job["args"]
          else
            Sidekiq.load_json(elem.split("-", 2)[1])
          end
        end

        if base_job
          base_job.merge("args" => final_args, "debounce_key" => debounce_key)
        else
          # Old format fallback - normalize to get queue from class
          job_class = debounce_key.split("/")[2]
          normalize_item("args" => final_args, "class" => Object.const_get(job_class), "debounce_key" => debounce_key)
        end
      end
    end
  end
end

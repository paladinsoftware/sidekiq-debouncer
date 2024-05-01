# frozen_string_literal: true

require "sidekiq/cli"
require "spec_helper"
require_relative "../../support/context"

describe Sidekiq::Debouncer::Launcher do
  include_context "sidekiq"

  it "runs the poller" do
    expect_any_instance_of(Sidekiq::Debouncer::Poller).to receive(:start).once

    launcher = Sidekiq::Launcher.new(sidekiq_config)
    launcher.run
    launcher.stop
  end
end

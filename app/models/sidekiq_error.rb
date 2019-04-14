class SidekiqError < ApplicationRecord
  belongs_to :sidekiq_status
end
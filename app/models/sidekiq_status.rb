class SidekiqStatus < ApplicationRecord
  belongs_to :url_list
  has_many :sidekiq_errors
end
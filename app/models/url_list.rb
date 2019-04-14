class UrlList < ApplicationRecord
  serialize :urls
  belongs_to :user
  has_one :sidekiq_status
end
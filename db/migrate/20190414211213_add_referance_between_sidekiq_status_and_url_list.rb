class AddReferanceBetweenSidekiqStatusAndUrlList < ActiveRecord::Migration[5.2]
  def change
    add_column :sidekiq_statuses, :url_list_id, :integer
    add_column :url_lists, :sidekiq_status_id, :integer
  end
end

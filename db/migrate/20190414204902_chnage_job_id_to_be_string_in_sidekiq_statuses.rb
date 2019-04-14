class ChnageJobIdToBeStringInSidekiqStatuses < ActiveRecord::Migration[5.2]
  def change
    change_column :sidekiq_statuses, :job_id, :string
  end
end

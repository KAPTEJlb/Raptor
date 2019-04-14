class CreateSidekiqStatus < ActiveRecord::Migration[5.2]
  def change
    create_table :sidekiq_statuses do |t|
      t.integer :job_id
      t.integer :progress
      t.string :message
    end
  end
end
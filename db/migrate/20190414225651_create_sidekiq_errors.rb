class CreateSidekiqErrors < ActiveRecord::Migration[5.2]
  def change
    create_table :sidekiq_errors do |t|
      t.string :error_messages
      t.references :sidekiq_status
    end
  end
end

class CreateUrlLists < ActiveRecord::Migration[5.2]
  def change
    create_table :url_lists do |t|
      t.references :user
      t.text :urls

      t.timestamps
    end
  end
end

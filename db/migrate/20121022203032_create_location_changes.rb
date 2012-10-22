class CreateLocationChanges < ActiveRecord::Migration
  def change
    create_table :location_changes do |t|
      t.integer :admin_id
      t.integer :location_id
      t.text :change
      t.timestamps
    end
  end
end

class AddNameToLocationChanges < ActiveRecord::Migration
  def change
    add_column :location_changes, :name, :string, :default => ""
  end
end

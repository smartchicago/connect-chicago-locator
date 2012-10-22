class AddSlugToLocationChanges < ActiveRecord::Migration
  def change
    add_column :location_changes, :slug, :string, :default => ""
  end
end

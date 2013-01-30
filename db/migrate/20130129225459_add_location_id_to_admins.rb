class AddLocationIdToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :location_id, :integer, :null => true
  end
end

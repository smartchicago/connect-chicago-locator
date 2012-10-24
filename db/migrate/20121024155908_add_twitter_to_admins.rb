class AddTwitterToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :twitter_handle, :string, :null => true
  end
end

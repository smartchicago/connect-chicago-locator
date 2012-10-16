class AddAdminFields < ActiveRecord::Migration
  def change
    add_column :admins, :first_name, :string, :default => ""
    add_column :admins, :last_name, :string, :default => ""
    add_column :admins, :organization, :string, :default => ""
  end
end

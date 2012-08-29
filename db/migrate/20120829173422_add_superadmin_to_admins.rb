class AddSuperadminToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :superadmin, :boolean, :default => false
  end
end

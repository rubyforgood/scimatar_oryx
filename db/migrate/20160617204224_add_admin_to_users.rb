class AddAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :site_admin, :boolean, default: false
  end
end

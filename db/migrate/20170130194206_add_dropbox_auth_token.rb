class AddDropboxAuthToken < ActiveRecord::Migration
  def up
    change_table :teams do |t|
      t.string :dropbox_auth_token
    end
  end
  def down
    remove_column :teams, :dropbox_auth_token
  end
end

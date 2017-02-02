class AddState < ActiveRecord::Migration
  def up
    change_table :teams do |t|
      t.string :state
    end
  end
  def down
    remove_column :teams, :state
  end
end

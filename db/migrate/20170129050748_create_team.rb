class CreateTeam < ActiveRecord::Migration
  def up
    create_table :teams do |t|
      t.string :access_token,
               :scope,
               :user_id,
               :team_name,
               :team_id,
               :bot_user_id,
               :bot_access_token
    end
  end

  def down
    drop_table :teams
  end
end

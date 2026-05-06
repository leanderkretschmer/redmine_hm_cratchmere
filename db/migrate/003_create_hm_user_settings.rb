class CreateHmUserSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :hm_user_settings do |t|
      t.references :user, type: :integer, null: false, foreign_key: true, index: { unique: true }
      t.integer :daily_target_minutes
      t.integer :weekly_target_minutes
      t.integer :max_break_minutes
      t.boolean :notify_target_reached, null: false, default: true
      t.boolean :notify_break_over,     null: false, default: true
      t.timestamps
    end
  end
end

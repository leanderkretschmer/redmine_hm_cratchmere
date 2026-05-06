class CreateHmWorkEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :hm_work_entries do |t|
      t.references :user, type: :integer, null: false, foreign_key: true
      t.datetime   :started_at, null: false
      t.datetime   :ended_at
      t.string     :state, null: false, default: 'running', limit: 16
      t.text       :notes
      t.string     :created_ip, limit: 64
      t.timestamps
    end
    add_index :hm_work_entries, [:user_id, :started_at]
    add_index :hm_work_entries, [:user_id, :state]
  end
end

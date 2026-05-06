class CreateHmBreakEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :hm_break_entries do |t|
      t.references :hm_work_entry, null: false, foreign_key: true, index: true
      t.datetime   :started_at, null: false
      t.datetime   :ended_at
      t.text       :notes
      t.timestamps
    end
  end
end

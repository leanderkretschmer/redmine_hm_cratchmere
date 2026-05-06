class CreateHmAbsences < ActiveRecord::Migration[7.0]
  def change
    create_table :hm_absences do |t|
      t.references :user, type: :integer, null: false, foreign_key: true
      t.string   :kind,      null: false, limit: 16
      t.date     :starts_on, null: false
      t.date     :ends_on,   null: false
      t.string   :status,    null: false, default: 'requested', limit: 16
      t.text     :reason
      t.integer  :approved_by_id
      t.datetime :approved_at
      t.timestamps
    end
    add_index :hm_absences, [:user_id, :kind, :starts_on]
    add_index :hm_absences, [:status, :starts_on]
    add_index :hm_absences, :starts_on
    add_index :hm_absences, :ends_on
  end
end

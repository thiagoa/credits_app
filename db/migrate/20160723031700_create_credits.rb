class CreateCredits < ActiveRecord::Migration[5.0]
  def change
    create_table :credits do |t|
      t.references :user, foreign_key: true, null: false
      t.string :type, null: false
      t.integer :amount, null: false
      t.date :expires_at
      t.boolean :processed, null: false, default: true

      t.timestamps
    end
  end
end

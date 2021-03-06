class CreateBookstores < ActiveRecord::Migration
  def self.up
    create_table :bookstores do |t|
      t.text :name, :null => false
      t.string :zip_code
      t.text :address
      t.text :note
      t.string :telephone_number
      t.string :fax_number
      t.string :url
      t.integer :position
      t.datetime :deleted_at

      t.timestamps
    end
  end

  def self.down
    drop_table :bookstores
  end
end

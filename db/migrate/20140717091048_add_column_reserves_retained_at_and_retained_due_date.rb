class AddColumnReservesRetainedAtAndRetainedDueDate < ActiveRecord::Migration
  def change
    add_column :reserves, :retained_at, :timestamp
    add_column :reserves, :retain_due_date, :timestamp
  end
end

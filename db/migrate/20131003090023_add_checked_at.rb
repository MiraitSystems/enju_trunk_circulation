class AddCheckedAt < ActiveRecord::Migration
  def up
    add_column :checked_items, :checked_at, :datetime
    add_column :checkouts, :checked_at, :datetime
  end

  def down
    remove_column :checked_items, :checked_at
    remove_column :checkouts, :checked_at
  end
end

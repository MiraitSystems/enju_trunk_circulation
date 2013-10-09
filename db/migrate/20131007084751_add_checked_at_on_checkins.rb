class AddCheckedAtOnCheckins < ActiveRecord::Migration
  def up
    add_column :checkins, :checked_at, :datetime
  end

  def down
   remove_column :checkins, :checked_at
  end
end

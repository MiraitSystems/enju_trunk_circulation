class AddColumnDaysOverdueToUserGroupHasCheckoutTypes < ActiveRecord::Migration
  def change
    add_column :user_group_has_checkout_types, :days_overdue, :integer, :default => 1
  end
end

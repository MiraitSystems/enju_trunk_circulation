class UserGroupHasCheckoutType < ActiveRecord::Base
  attr_accessible :checkout_type, :user_group, :user_group_id, :checkout_type_id, :checkout_limit,
                  :checkout_period, :checkout_renewal_limit, :reservation_limit, :reservation_expired_period,
                  :set_due_date_before_closing_day, :note, :days_overdue
  scope :available_for_item, lambda{|item| where(:checkout_type_id => item.checkout_type.id)}
  scope :available_for_carrier_type # , lambda{|carrier_type| {:include => {:checkout_type => :carrier_types}, :conditions => ['carrier_types.id = ?', carrier_type.id]}}

  belongs_to :user_group, :validate => true
  belongs_to :checkout_type, :validate => true

  validates_presence_of :user_group, :checkout_type, :days_overdue
  validates_associated :user_group, :checkout_type
  validates_uniqueness_of :checkout_type_id, :scope => :user_group_id

  acts_as_list :scope => :user_group_id

  def self.update_current_checkout_count
    sql = [
      'SELECT count(checkouts.id) as current_checkout_count,
        users.user_group_id,
        items.checkout_type_id
        FROM checkouts LEFT OUTER JOIN items
        ON (checkouts.item_id = items.id)
        LEFT OUTER JOIN users
        ON (users.id = checkouts.user_id)
        WHERE checkouts.checkin_id IS NULL
        GROUP BY user_group_id, checkout_type_id;'
    ]
    UserGroupHasCheckoutType.find_by_sql(sql).each do |result|
      update_sql = [
        'UPDATE user_group_has_checkout_types
          SET current_checkout_count = ?
          WHERE user_group_id = ? AND checkout_type_id = ?;',
          result.current_checkout_count, result.user_group_id, result.checkout_type_id
      ]
      ActiveRecord::Base.connection.execute(
        self.send(:sanitize_sql_array, update_sql)
      )
    end
  end
end

# == Schema Information
#
# Table name: user_group_has_checkout_types
#
#  id                              :integer         not null, primary key
#  user_group_id                   :integer         not null
#  checkout_type_id                :integer         not null
#  checkout_limit                  :integer         default(0), not null
#  checkout_period                 :integer         default(0), not null
#  checkout_renewal_limit          :integer         default(0), not null
#  reservation_limit               :integer         default(0), not null
#  reservation_expired_period      :integer         default(7), not null
#  set_due_date_before_closing_day :boolean         default(FALSE), not null
#  fixed_due_date                  :datetime
#  note                            :text
#  position                        :integer
#  created_at                      :datetime
#  updated_at                      :datetime
#  current_checkout_count          :integer
#


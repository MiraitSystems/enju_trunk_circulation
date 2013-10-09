class Basket < ActiveRecord::Base
  attr_accessible :note, :user_number, :user, :basket_type

  default_scope :order => 'id DESC'
  scope :will_expire, lambda { |date| {:conditions => ['basket_type = ? AND created_at < ?', 0, date]} }
  belongs_to :user, :validate => true
  has_many :checked_items, :dependent => :destroy
  has_many :items, :through => :checked_items
  has_many :checkouts
  has_many :checkins
  #TODO
  #acts_as_paranoid

  validates_associated :user, :on => :create
  # 貸出完了後にかごのユーザidは破棄する
  validates_presence_of :user, :on => :create
  validate :check_suspended

  attr_accessor :user_number
  attr_accessible :item_id, :user_id

  def check_suspended
    state_id = self.try(:user).try(:user_status).try(:state_id) || 10 #TODO when state_id is NILL
    if self.user
      errors[:base] << I18n.t('basket.this_account_is_suspended') unless state_id < 3  # self.user.active_for_authentication?
    else
      errors[:base] << I18n.t('user.not_found')
    end
  end

  def basket_checkout(librarian)
    if self.checked_items.size == 0
      errors[:base] = I18n.t('basket.no_checked_item')
      return nil
    end
    begin
    checkout = nil
    Item.transaction do
      self.checked_items.each do |checked_item|
        checked_item.ignore_restriction = '1'
        if checked_item.available_for_checkout?
          option = checked_item.item.checkout!(self.user, librarian)
          checkout = Checkout.new(:librarian_id => librarian.id, :item_id => checked_item.item.id, :basket_id => self.id, :user_id => self.user_id, 
                                  :due_date => checked_item.due_date, :available_for_extend => true, :checked_at => checked_item.checked_at)
          checkout.checkout_renewal_count = option[:extend] + 1 if option[:extend]
          checkout.save!
        else
          errors[:base] << I18n.t('activerecord.errors.messages.checked_item.not_available_for_checkout')
#          errors[:base] << 'checked_item.not_available_for_checkout'
          return false          
        end
      end
      CheckedItem.destroy_all(:basket_id => self.id)
      self.destroy
    end
    rescue Exception => e
      logger.error "Failed to checkout: #{e}"
      errors[:base] = checkout.try(:errors).try(:full_messages).try(:flatten)
      return false
    end
  end

  def self.expire
    Basket.will_expire(Time.zone.now.beginning_of_day).destroy_all
    logger.info "#{Time.zone.now} baskets expired!"
  end

  def update_checked_items(params)
    return unless params.try(:keys)
    params.keys.each do |id|
      checked_item = self.checked_items.find(id)
      checked_item.update_attributes(params[id])
    end
  end
end

# == Schema Information
#
# Table name: baskets
#
#  id           :integer         not null, primary key
#  user_id      :integer
#  note         :text
#  type         :string(255)
#  lock_version :integer         default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#


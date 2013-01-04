class CheckoutHistory < ActiveRecord::Base
  attr_accessible :operation, :checkout_id, :checkin_id, :reserve_id, 
                  :item_id, :manifestation_id, :user_id, :librarian_id
 
  belongs_to :checkout
  belongs_to :checkin
  belongs_to :reserve
  belongs_to :manifestation
  belongs_to :item
  belongs_to :user
  belongs_to :librarian, :class_name => 'User', :foreign_key => :librarian_id

  before_save :set_manifestation

  default_scope :order => 'created_at ASC'
  paginates_per 25

  def self.store_history(operation, object)
    history = nil
    case operation
    when "checkout"
      history = CheckoutHistory.new(:operation => 1, :checkout_id => object.id, :item_id => object.item_id, :user_id => object.user_id)      
    when "checkin"
      history = CheckoutHistory.new(:operation => 2, :checkin_id => object.id, :item_id => object.item_id)
    when "reserve"
      history = CheckoutHistory.new(:operation => 3, :reserve_id => object.id, :manifestation_id => object.manifestation_id, :item_id => object.item_id, :user_id => object.user_id)      
    when "extend"
      history = CheckoutHistory.new(:operation => 4, :checkout_id => object.id, :item_id => object.item_id, :user_id => object.user_id)      
    end
    history.update_attributes(:librarian_id => object.librarian_id)
  end

  def set_manifestation
    self.manifestation = self.item.manifestation unless self.manifestation
  end
end

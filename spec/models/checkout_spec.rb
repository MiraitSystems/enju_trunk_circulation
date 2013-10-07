# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Checkout do
  #pending "add some examples to (or delete) #{__FILE__}"
  fixtures :all

  describe 'validates' do
    describe '' do
      #validates_associated :user, :item, :librarian, :checkin #, :basket
    end
    describe '' do
      #validates_presence_of :item_id, :basket_id, :due_date
      it '' # TODO
    end
    describe '' do
      #validates_uniqueness_of :item_id, :scope => [:basket_id, :user_id]
      it '' # TODO
    end
    describe '' do
      #validate :is_not_checked?, :on => :create
      it '' # TODO
    end
    describe '' do
      #validates_date :due_date, :allow_blank => true
      it '' # TODO
    end
    describe '' do
      #validate :check_due_date
      it '' # TODO
    end
  end

  describe 'scope' do
    # TODO
    it "should respond to not_returned" do
      Checkout.not_returned.size.should > 0
    end
    it "should respond to overdue" do
      Checkout.overdue(Time.zone.now).size.should > 0
      Checkout.not_returned.size.should > Checkout.overdue(Time.zone.now).size
    end
  end

  describe '#create' do
    describe '' do
      #after_create :store_history
      it '' # TODO
    end
  end

  describe '#day_of_overdue' do
    it '' # TODO: immediately
  end

  describe '#is_not_checked?' do
    it '' # TODO
  end

  describe '#checkout_renewable?' do
    it '' # TODO: immediately
    it "should respond to checkout_renewable?" do
      checkouts(:checkout_00001).checkout_renewable?.should be_true
      checkouts(:checkout_00002).checkout_renewable?.should be_false
    end
  end

  describe '#reserved?' do
    it '' # TODO: immediately
    it "should respond to reserved?" do
      checkouts(:checkout_00001).reserved?.should be_false
      checkouts(:checkout_00012).reserved?.should be_true
    end
  end

  describe '#over_checkout_renewal_limit?' do
    it '' # TODO: immediately
  end

  describe '#overdue?' do
    it '' # TODO: immediately
    it "should respond to overdue?" do
      checkouts(:checkout_00001).overdue?.should be_false
      checkouts(:checkout_00006).overdue?.should be_true
    end
  end

  describe '#is_today_due_date?' do
    it '' # TODO: immediately
    it "should respond to is_today_due_date?" do
      checkouts(:checkout_00001).is_today_due_date?.should be_false
    end
  end

  describe '#set_renew_due_date' do
    it '' # TODO: immediately
  end

  describe '#check_due_date' do
    it '' # TODO
  end

  describe '#new_loan' do
    it '' # TODO: immediately
  end

  describe '.manifestations_count' do
    it '' # TODO
  end

  describe '.send_due_date_notification' do
    it '' # TODO: immediately
    it "should respond to send_due_date_notification" do
      Checkout.send_due_date_notification.should eq 2
    end
  end

  describe '.send_overdue_notification' do
    it '' # TODO: immediately
    it "should respond to send_overdue_notification" do
      Checkout.send_overdue_notification.should eq 1
    end
  end

  describe '.apend_to_reminder_list' do
    it '' # TODO
  end

  describe '.output_checkouts' do
    it '' # TODO
  end

  describe '.output_checkoutlist_pdf' do
    it '' # TODO
  end

  describe '.output_checkoutlist_csv' do
    it '' # TODO
  end

  describe '.get_checkoutlists_pdf' do
    it '' # TODO
  end

  describe '.get_checkoutlists_tsv' do
    it '' # TODO: immediately
  end

  describe '#store_history' do
    it '' # TODO
  end
end

# == Schema Information
#
# Table name: checkouts
#
#  id                     :integer         not null, primary key
#  user_id                :integer
#  item_id                :integer         not null
#  checkin_id             :integer
#  librarian_id           :integer
#  basket_id              :integer
#  due_date               :datetime
#  checkout_renewal_count :integer         default(0), not null
#  lock_version           :integer         default(0), not null
#  created_at             :datetime
#  updated_at             :datetime
#


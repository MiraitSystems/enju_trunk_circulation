# -*- encoding: utf-8 -*-
require 'spec_helper'

describe CheckedItem do
  fixtures :all

  describe 'validates' do
    describe '' do
      #validates_associated :item, :basket, :on => :update
      it '' # TODO
    end
    describe '' do
      #validates_presence_of :item, :basket, :due_date, :on => :update
      it '' # TODO
    end
    describe '' do
      #validates_uniqueness_of :item_id, :scope => :basket_id
    end
    describe '' do
      #validate :available_for_checkout?, :on => :create
    end
    describe '' do
      #before_validation :set_due_date, :on => :create
    end
  end
 
  describe '#available_for_checkout?' do
    it '' # TODO: immediately
    # 以下のテストじゃ足らないので強化すること
    it "should respond to available_for_checkout?" do
      checked_items(:checked_item_00001).available_for_checkout?.should_not be_true
    end
  end
 
  describe '#item_checkout_type' do
    it '' # TODO
  end
 
  describe '#set_due_date' do
    it '' # TODO: immediately
  end
 
  describe '#in_transaction?' do
    it '' # TODO
  end
 
  describe '#destroy_reservation' do
    it '' # TODO: immediately
  end
 
  describe '#available_for_reserve_checkout?' do
    it '' # TODO: immediately
  end
 
  describe '#exchange_reserve_item' do
    it '' # TODO: immediately
  end
end

# == Schema Information
#
# Table name: checked_items
#
#  id         :integer         not null, primary key
#  item_id    :integer         not null
#  basket_id  :integer         not null
#  due_date   :datetime        not null
#  created_at :datetime
#  updated_at :datetime
#


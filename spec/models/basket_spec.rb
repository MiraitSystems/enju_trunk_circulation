# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Basket do
  #pending "add some examples to (or delete) #{__FILE__}"
  fixtures :all

  describe '' do
    describe '' do
      #validates_associated :user, :on => :create
      it '' #TODO:
    end 
    describe '' do
      # 貸出完了後にかごのユーザidは破棄する
      #validates_presence_of :user, :on => :create
    end
    describe '' do
      # validate :check_suspended
    end
  end

  describe '#create' do
    it "should not create basket when user is not active" do
      Basket.create(:user => users(:user4)).id.should be_nil
    end
  end

  describe '#check_suspended' do
    it '' #TODO: immediately
  end

  describe '#basket_checkout' do
    it '' #TODO: immediately
  end

  describe '.expire' do
    it '' #TODO
  end

  describe '#update_checked_items' do
    it '' #TODO
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


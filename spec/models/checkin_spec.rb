# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Checkin do
  #pending "add some examples to (or delete) #{__FILE__}"
  fixtures :all

  describe '#create' do
    #validates_presence_of :item_identifier, :on => :create
    it '' # TODO
  end

  describe '#update' do
    #validates_presence_of :item, :basket, :on => :update
    #validates_associated :item, :librarian, :basket, :on => :update
  end

  describe '#item_checkin' do
    it '' # TODO: immediately
  end

  describe '#store_history' do
    it '' # TODO
  end
end

# == Schema Information
#
# Table name: checkins
#
#  id           :integer         not null, primary key
#  item_id      :integer         not null
#  librarian_id :integer
#  basket_id    :integer
#  created_at   :datetime
#  updated_at   :datetime
#


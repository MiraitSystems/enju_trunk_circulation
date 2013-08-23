# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Reserve do
  fixtures :all

  describe 'validates' do
    describe '' do
      #validates_associated :user, :librarian, :item, :request_status_type, :manifestation
      it '' # TODO:
    end
    describe '' do
      #validates_presence_of :user, :manifestation, :request_status_type, :expired_at, :created_by
      it '' # TODO:
    end
    describe '' do
      #validates_date :expired_at, :allow_blank => true
      it '' # TODO:
    end
    describe '' do
      #validate :manifestation_must_include_item
      it '' # TODO:
    end
    describe '' do
      #validate :available_for_reservation?, :on => :create
      it '' # TODO:
    end
    describe '' do
      #before_validation :set_item_and_manifestation, :on => :create
      it '' # TODO:
    end
    describe '' do
      #before_validation :set_expired_at
      it '' # TODO:
    end
    describe '' do
      #before_validation :set_request_status, :on => :create
      it '' # TODO:
    end
  end

  describe 'scope' do
    # 以下、元のテスト。実際と動きが変わっている可能性があるので要確認	
    it "should have reservations that will be expired" do
      Reserve.will_expire_retained(Time.zone.now).size.should eq 1
    end
    it "should have completed reservation" do
      Reserve.completed.size.should eq 1
    end
  end

  describe '#create' do
    #after_create :store_history, :send_notice
    it '' # TODO:
    # 以下、元のテスト。実際と動きが変わっている可能性があるので要確認	
    it "should not create when expired_at is before today" do
      reserve = Reserve.new(:user => FactoryGirl.create(:user), :manifestation => FactoryGirl.create(:manifestation), :receipt_library_id => FactoryGirl.create(:library).id, :expired_at => 1.week.ago)
      reserve.should_not be_valid
    end
    it "should not create when user is locked" do
      reserve = Reserve.new(:user => FactoryGirl.create(:locked_user), :manifestation => FactoryGirl.create(:manifestation), :receipt_library_id => FactoryGirl.create(:library).id, :expired_at => 1.week.from_now)
      reserve.should_not be_valid
    end
    it "should not create when user's expired_at is over" do
      reserve = Reserve.new(:user => FactoryGirl.create(:expired_at_is_over_user), :manifestation => FactoryGirl.create(:manifestation), :receipt_library_id => FactoryGirl.create(:library).id, :expired_at => 1.week.from_now)
     reserve.should_not be_valid
    end
    it "should update when user's expired_at is over" do
      reserve = FactoryGirl.create(:reserve)
      reserve.stub(:update_attributes).with(:expired_at => 2.week.from_now).and_return(true)
    end
    it "should not update when user's expired_at is over" do
      reserve = FactoryGirl.create(:reserve)
      reserve.stub(:update_attributes).with(:user => FactoryGirl.create(:expired_at_is_over_user)).and_return(false)
    end
  end

  describe 'state_machine' do
    it '' # TODO:
    # 以下、元のテスト。実際と動きが変わっている可能性があるので要確認	
    it "should cancel reservation" do
      p "p #{reserves(:reserve_00001)}"
      reserves(:reserve_00001).sm_cancel!
      p reserves(:reserve_00001).canceled_at
      reserves(:reserve_00001).canceled_at.should be_true
      reserves(:reserve_00001).request_status_type.name.should eq 'Cannot Fulfill Request'
    end
  end

  describe 'search' do
    it '' # TODO: immediately
  end

  describe '#reserved_library' do
    it '' # TODO: immediately
  end

  describe '#reserved_library_name' do
    it '' # TODO:
  end

  describe '#set_item_and_manifestation' do
    it '' # TODO:
  end

  describe '#set_request_status' do
    it '' # TODO:
  end

  describe '#set_expired_at' do
    it '' # TODO:
  end

  describe '#retain_item' do
    it '' # TODO: immediately
  end

  describe '#do_request' do
    it '' # TODO: immediately
  end

  describe '#new_reserve' do
    it '' # TODO: immediately
    # 以下、元のテスト
    it "should retained" do
      reserve = Reserve.new(:user => users(:user2), :manifestation => manifestations(:manifestation_00004), :receipt_library_id => libraries(:library_00002).id, :expired_at => 1.week.from_now, :created_by=> users(:librarian2))
      reserve.save
      reserve.new_reserve
      reserve.state.should eq 'retained'
    end
    it "should reqesuted when item_identifier is null" do
      reserve = Reserve.new(:user => users(:user2), :manifestation => manifestations(:manifestation_00024), :receipt_library_id => libraries(:library_00002).id, :expired_at => 1.week.from_now, :created_by=> users(:librarian2))
      reserve.save
      reserve.new_reserve
      reserve.state.should eq 'requested'
    end
    it "should reqested when a shef of items is not opened" do
      reserve = Reserve.new(:user => users(:user2), :manifestation => manifestations(:manifestation_00025), :receipt_library_id => libraries(:library_00002).id, :expired_at => 1.week.from_now, :created_by=> users(:librarian2))
       reserve.save
      reserve.new_reserve
      reserve.state.should eq 'requested'
    end
    it "should reqested when a shef of items is not on shelf" do
      reserve = Reserve.new(:user => users(:user2), :manifestation => manifestations(:manifestation_00026), :receipt_library_id => libraries(:library_00002).id, :expired_at => 1.week.from_now, :created_by=> users(:librarian2))
      reserve.save
      reserve.new_reserve
      reserve.state.should eq 'requested'
    end
  end

  describe '#manifestation_must_include_item' do
    it '' # TODO: immediately
  end

  describe '#next_reservation' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should have next reservation" do
      reserves(:reserve_00001).next_reservation.should be_true
    end
    it "should not have next reservation" do
      reserves(:reserve_00002).next_reservation.should be_nil
    end
  end

  describe '#retain' do
    it '' # TODO: immediately
  end

  describe '#revert_request' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should requested when reserve state was not retained" do
      reserves(:reserve_00020).revert_request
      reserves(:reserve_00020).state.should eq 'requested'
      reserves(:reserve_00020).position.should eq 1
    end
  end

  describe '#to_process' do
    it '' # TODO: immediately
  end

  describe '#expire' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should expire reservation" do
      reserves(:reserve_00001).expire
      reserves(:reserve_00001).request_status_type.name.should eq 'Expired'
    end
  end

  describe '#cancel' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should retained when retained reserve was canceled" do
      reserves(:reserve_00020).cancel
      reserves(:reserve_00021).state.should eq 'retained'
    end
  end

  describe '#checkout' do
    it '' # TODO: immediately
  end

  describe '#available_for_checkout?' do
    it '' # TODO: immediately
  end

  describe '#available_for_update?' do
    it '' # TODO: immediately
  end

  describe '#send_message' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should send accepted message" do
      old_admin_count = User.find('admin').received_messages.count
      old_user_count = reserves(:reserve_00002).user.received_messages.count
      reserves(:reserve_00002).send_message('accepted').should be_true
      # 予約者と図書館の両方に送られる
      User.find('admin').received_messages.count.should eq old_admin_count + 1
      reserves(:reserve_00002).user.received_messages.count.should eq old_user_count + 1
    end
    it "should send expired message" do
      old_count = MessageRequest.count
      reserves(:reserve_00002).send_message('expired').should be_true
      MessageRequest.count.should eq old_count + 1
    end
    it "should send message to library" do
      Reserve.send_message_to_library('expired', :manifestations => Reserve.not_sent_expiration_notice_to_library.collect(&:manifestation)).should be_true
    end
  end

  describe '.send_message_to_library' do
    it '' # TODO: immediately
  end

  describe '#send_notice' do
    it '' # TODO:
  end

  describe '.expire' do
    it '' # TODO:
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should expire all reservations" do
      assert Reserve.expire.should be_true
    end
  end

  describe '#available_for_reservation?' do
    it '' # TODO: immediately
  end

  describe '#position_update' do
    it '' # TODO: immediately
  end

  describe '#retained_mail_title' do
    it '' # TODO:
  end

  describe '#retained_mail_message' do
    it '' # TODO:
  end

  describe '.information_type_ids' do
    it '' # TODO:
  end

  describe '.unnecessary_type_ids' do
    it '' # TODO:
  end

  describe '.mail_type_ids' do
    it '' # TODO:
  end

  describe '.all_telephone_type_ids' do
    it '' # TODO:
  end

  describe '.informations' do
    it '' # TODO: immediately
  end

  describe '.get_information_type' do
    it '' # TODO: immediately
  end

  describe '.states' do
    it '' # TODO:
  end

  describe '.show_user_states' do
    it '' # TODO:
  end

  describe '#can_checkout?' do
    it '' # TODO: immediately
  end

  describe '#can_cancel?' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should be canceled" do
      reserves(:reserve_00001).can_cancel?.should be_true # requested
      reserves(:reserve_00012).can_cancel?.should be_true # retained
      reserves(:reserve_00016).can_cancel?.should_not be_true # in_process
      reserves(:reserve_00017).can_cancel?.should_not be_true # completed
      reserves(:reserve_00019).can_cancel?.should_not be_true # expired
    end
  end

  describe '#can_edit?' do
    it '' # TODO: immediately
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should be edited" do
      reserves(:reserve_00001).can_edit?.should be_true # requested
      reserves(:reserve_00012).can_edit?.should be_true # retained
      reserves(:reserve_00016).can_edit?.should be_true # in_process
      reserves(:reserve_00017).can_edit?.should_not be_true # completed
      reserves(:reserve_00018).can_edit?.should_not be_true # canceled
      reserves(:reserve_00019).can_edit?.should_not be_true # expired
    end
  end

  describe '#user_can_show?' do
    it '' # TODO:
  end

  describe '.get_reserve' do
    it '' # TODO:
  end

  describe '.get_reserves' do
    it '' # TODO:
  end

  describe '.get_reserve_list_user_tsv' do
    it '' # TODO:
  end

  describe '.get_reserve_list_all_pdf' do
    it '' # TODO:
  end

  describe '.get_reserve_list_picking_pdf' do
    it '' # TODO:
  end

  describe '.get_reserve_list_all_tsv' do
    it '' # TODO:
  end

  describe '.get_reservelist_pdf' do
    it '' # TODO:
  end

  describe '.get_reservelist_tsv' do
    it '' # TODO:
  end

  describe '.get_retained_manifestation_list_pdf' do
    it '' # TODO:
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should got a pdf file of retained manifestations" do
      retained_manifestations = Reserve.retained
      data = Reserve.get_retained_manifestation_list_pdf(retained_manifestations)
      data.should_not be_nil
    end
  end

  describe '.get_retained_manifestation_list_tsv' do
    it '' # TODO:
    # 以下、元のテスト。実際と差異がある場合があるので動作確認すること
    it "should got a pdf file of retained manifestations" do
      retained_manifestations = Reserve.retained
      data = Reserve.get_retained_manifestation_list_tsv(retained_manifestations)
      data.should_not be_nil
      cnt = 0
      data.length.times { |i| cnt += 1 if data[i] =~ /^[\n]$/ }
      cnt.should eq 4 # line of encord, title, and retained reserves
    end
  end

  describe '#store_history' do
    it '' # TODO:
  end
end

# == Schema Information
#
# Table name: reserves
#
#  id                           :integer         not null, primary key
#  user_id                      :integer         not null
#  manifestation_id             :integer         not null
#  item_id                      :integer
#  request_status_type_id       :integer         not null
#  checked_out_at               :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  canceled_at                  :datetime
#  expired_at                   :datetime
#  deleted_at                   :datetime
#  state                        :string(255)
#  expiration_notice_to_patron  :boolean         default(FALSE)
#  expiration_notice_to_library :boolean         default(FALSE)
#


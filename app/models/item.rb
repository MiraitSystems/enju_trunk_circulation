# -*- encoding: utf-8 -*-
class Item < ActiveRecord::Base
  def next_reservation
    Reserve.waiting.where(:manifestation_id => self.manifestation.id).first
  end

  def reserved?
    return true unless Reserve.waiting.where(:item_id => self.id).blank?
    return true if self.next_reservation
    false
  end

  def reserve
    Reserve.waiting.where(:item_id => self.id).first 
  end

  def reservable?
    return false if ['Lost', 'Claimed Returned Or Never Borrowed'].include?(self.circulation_status.name)
    return false if self.item_identifier.blank?
    true
  end

  def available_checkin?
    return false if ['Circulation Status Undefined'].include?(self.circulation_status.name)
    true
  end

  def rent?
    return true if self.checkouts.not_returned.select(:item_id).detect{|checkout| checkout.item_id == self.id}
    false
  end

  def reserved_by_user?(user)
    if self.reserve
      return true if self.reserve.user == user
    end
    false
  end

  def checkout_reserved_item(user)
    reservation = Reserve.waiting.where(:user_id => user.id, :manifestation_id => self.manifestation.id).first rescue nil
    if reservation
      logger.error "checkouts reservation: #{reservation.id}"
      reservation.item = self
      reservation.sm_complete!
      reservation.update_attributes(:checked_out_at => Time.zone.now)     
      return reservation
    end
  end

  def available_for_checkout?
    circulation_statuses = CirculationStatus.available_for_checkout.select(:id)
    circulation_statuses << CirculationStatus.where(:name => 'On Loan').first if SystemConfiguration.get('checkout.auto_checkin')
    return true if circulation_statuses.include?(self.circulation_status) && self.item_identifier
    false
  end

  def available_for_retain?
    circulation_statuses = CirculationStatus.available_for_retain.select(:id)
    return true if circulation_statuses.include?(self.circulation_status) && self.item_identifier && self.shelf.open_access == 0 
    false
  end

  def available_for_reserve_with_config?
    c = CirculationStatus.where(:name => 'On Loan').first
    return true if c.id == self.circulation_status.id
    false
  end

  def checkout!(user, librarian = nil)
    circulation_status_on_loan = CirculationStatus.where(:name => 'On Loan').first
    if self.circulation_status == circulation_status_on_loan && SystemConfiguration.get('checkout.auto_checkin')
      @basket = Basket.new(:user => librarian)
      @basket.save(:validate => false)
      @checkin = @basket.checkins.new(:item_id => self.id, :librarian_id => librarian.id)
      @checkin.save(:validate => false)
      @checkin.item_checkin(user, true)
    end
    self.circulation_status = circulation_status_on_loan
    reservation = checkout_reserved_item(user)
#    if self.reserved_by_user?(user)
#      reservation = self.reserve
#      reservation.sm_complete!
#      reservation.update_attributes(:checked_out_at => Time.zone.now)
#    end

    if save!
      if self.reserve and self.reserve.user != user
        self.reserve.revert_request rescue nil
      end
      reservation.position_update(reservation.manifestation) if reservation
      true
    end
  end

  def checkin!
    self.circulation_status = CirculationStatus.where(:name => 'Available On Shelf').first
    save(:validate => false)
  end

  def set_next_reservation
    return unless self.manifestation.next_reservation

    next_reservation = self.manifestation.next_reservation
    next_reservation_accept_library = Library.find(next_reservation.receipt_library_id)
    next_reservation.item = self
    if self.shelf.library == next_reservation_accept_library 
      next_reservation.sm_retain!
      next_reservation.send_message('retained')
    else
      next_reservation.sm_process!
      InterLibraryLoan.new.request_for_reserve(self, next_reservation_accept_library)
    end
  end

  def retain(librarian)
    Item.transaction do
      set_next_reservation
    end
  end
end

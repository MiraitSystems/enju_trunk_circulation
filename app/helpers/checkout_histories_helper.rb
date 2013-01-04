module CheckoutHistoriesHelper
  def operation(num, object)
    case num
    when 1
      if object.checkout
        link_to t('checkout_history.checkout'), user_checkout_path(object.user, object.checkout) 
      else
        t('checkout_history.checkout')
      end
    when 2
      if object.checkin
        link_to t('checkout_history.checkin'), object.checkin
      else
        t('checkout_history.checkin')
      end
    when 3
      if object.reserve
        link_to t('checkout_history.reserve'), object.reserve
      else
        t('checkout_history.reserve')
      end
    when 4
      if object.checkout
        link_to t('checkout_history.extend_checkout'), user_checkout_path(object.user, object.checkout)      
      else
        t('checkout_history.reserve')
      end
    end
  end
end

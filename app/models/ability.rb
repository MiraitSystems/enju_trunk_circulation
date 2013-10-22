class Ability
  def initialize_circulation(user, ip_address = nil)
    case user.try(:role).try(:name)
    when 'Administrator'
      can :manage, [
        Basket,
        CheckedItem,
        Checkin,
        Checkout,
        LendingPolicy,
        Reserve
      ]
    when 'Librarian'
      can [:index, :create, :update, :destroy, :show], Reserve
      can :manage, [
        Basket,
        CheckedItem,
        Checkin,
        Checkout,
        Reserve
      ]
      can :read, [
        LendingPolicy,
      ]
    when 'User'
      can [:index, :create], Checkout
      can :update, Checkout do |checkout|
        checkout.available_for_extend && checkout.user.id == user.id
      end
      can :show, Checkout do |checkout|
        checkout.user == user
      end
      can [:index, :create], Reserve
      can [:show, :update, :destroy, :output], Reserve do |reserve|
        reserve.user == user && reserve.expired_at.end_of_day > Time.zone.now
      end
    else
      can :index, Checkout
    end
  end
end

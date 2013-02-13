class CheckoutHistoriesController < ApplicationController
  add_breadcrumb "I18n.t('activerecord.models.checkout_history')", 'checkout_histories_path'
  def index
    access_denied unless current_user
    if current_user.has_role?('Librarian')
      @checkout_histories = CheckoutHistory.where(["DATE(created_at) = DATE(?)", Time.now]).page params[:page]
    else
      @checkout_histories = CheckoutHistory.where(["DATE(created_at) = DATE(?) AND librarian_id = ?", Time.now, current_user.id]).page params[:page]
    end
  end
end

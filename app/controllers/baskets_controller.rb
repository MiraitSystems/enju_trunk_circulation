class BasketsController < ApplicationController
  include NotificationSound
  before_filter :check_client_ip_address
  load_and_authorize_resource
  helper_method :get_user_if_nil
  cache_sweeper :basket_sweeper, :only => [:create, :update, :destroy]

  # GET /baskets
  # GET /baskets.json
  def index
    get_user_if_nil
    if @user
      @baskets = @user.baskets.page(params[:page])
    else
      redirect_to new_basket_url
      return
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @baskets }
    end
  end

  # GET /baskets/1
  # GET /baskets/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @basket }
    end
  end

  # GET /baskets/new
  # GET /baskets/new.json
  def new
    @basket = Basket.new
    @basket.user_number = params[:user_number]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @basket }
    end
  end

  # GET /baskets/1/edit
  def edit
  end

  # POST /baskets
  # POST /baskets.json
  def create
    @basket = Basket.new
    @user = User.where(:user_number => params[:basket][:user_number].strip).first rescue nil
    old_basket = Basket.where(:user_id => @user.id).first rescue nil
    if old_basket
      old_basket.checked_items.destroy_all rescue nil
      old_basket.destroy
    end
    if @user
      if @user.user_number?
        @basket.user = @user
      end
    end

    respond_to do |format|
      if @basket.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.basket'))
        format.html { redirect_to user_basket_checked_items_url(@basket.user, @basket) }
        format.json { render :json => @basket, :status => :created, :location => @basket }
      else
        format.html { render :action => "new" }
        format.json { render :json => @basket.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /baskets/1
  # PUT /baskets/1.json
  def update
    librarian = current_user
    unless @basket.basket_checkout(librarian)
      logger.error "unless basket checkout"
      flash[:message] = @basket.errors[:base]
      @basket.errors[:base].each do |error|
        flash[:message], flash[:sound] = error_message_and_sound(error)
      end
      redirect_to user_basket_checked_items_url(@basket.user, @basket)
      return
    end

    #@checkout_count = @basket.user.checkouts.count
    respond_to do |format|
      #if @basket.update_attributes({})
      logger.error "before basket save"
      if @basket.save(:validate => false)
        # 貸出完了時
        flash[:notice] = t('basket.checkout_completed')
        format.html { redirect_to(user_checkouts_url(@basket.user)) }
        format.json { head :no_content }
      else
        format.html { redirect_to(user_basket_checked_items_url(@basket.user, @basket)) }
        format.json { render :json => @basket.errors, :status => :unprocessable_entity }
      end
    end

  end

  # DELETE /baskets/1
  # DELETE /baskets/1.json
  def destroy
    @basket.destroy

    respond_to do |format|
      #format.html { redirect_to(user_baskets_url(@user)) }
      format.html { redirect_to user_checkouts_url(@basket.user) }
      format.json { head :no_content }
    end
  end
end

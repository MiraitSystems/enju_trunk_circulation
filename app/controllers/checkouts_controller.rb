class CheckoutsController < ApplicationController
  before_filter :store_location, :only => :index
  before_filter :get_user, :only => :index
  before_filter :get_user_if_nil, :except => [:index, :batchexec, :extend, :extend_checkout] # TODO
  helper_method :get_item
  after_filter :convert_charset, :only => :index
  before_filter :authenticate_user!, :except => [:batchexec]

  # GET /checkouts
  # GET /checkouts.json
  def index
    if params[:icalendar_token].present?
      icalendar_user = User.where(:checkout_icalendar_token => params[:icalendar_token]).first
      if icalendar_user.blank?
        raise ActiveRecord::RecordNotFound
      else
        checkouts = icalendar_user.checkouts.not_returned.order('due_date ASC')
      end
    else
      unless current_user
        access_denied; return
      end
    end

    unless icalendar_user
      # logged in as User
      unless current_user.try(:has_role?, 'Librarian')
        if current_user == @user
          # disp1. user checkouts
          checkouts = current_user.checkouts.not_returned.order('due_date ASC')
        else
          if @user
            access_denied
          else
            redirect_to user_checkouts_url(current_user)
          end
          return
        end
      # logged in as Librarian
      else
        if @user && @basket_id = params[:basket_id]
          checkouts = @user.checkouts.not_returned.where(:basket_id => @basket_id).order('due_date ASC')
        elsif @user
          # disp1. user checkouts
          checkouts = @user.checkouts.not_returned.order('due_date ASC')
        else
          @libraries = Library.find(:all).collect{|i| [ i.display_name, i.id ] }
          @selected_library = params[:library][:id] unless params[:library].blank?
          library = Library.find(:all).collect{|i| i.id} if params[:library].blank? or params[:library][:id].blank?
          library = params[:library][:id] if params[:library] and !params[:library][:id].blank?
          # disp2. over_due checkouts
          if params[:view] == 'overdue'
            date = 1.days.ago.end_of_day
            date = params[:days_overdue].to_i.days.ago.end_of_day if params[:days_overdue]
            checkouts = Checkout.overdue(date).joins(:item => [{:shelf => :library}]).where('libraries.id' => library).order('due_date ASC')
          else
          # disp3. all checkouts
           checkouts = Checkout.not_returned.joins(:item => [{:shelf => :library}]).where('libraries.id' => library).order('due_date ASC')
          end
        end
      end
    end

    @days_overdue = params[:days_overdue] ||= 1
    @checkouts = checkouts.page(params[:page])

    respond_to do |format|
      format.html {render :template => 'opac/checkouts/index' , :layout => 'opac' } if params[:opac]
      format.html # index.html.erb
      format.json { render :json => @checkouts }
      format.rss  { render :layout => false }
      format.ics
      #format.csv
      format.pdf  { 
        if @user
          send_data Checkout.output_checkouts(checkouts, @user, current_user).generate, :filename => Setting.checkouts_print.filename
        else
          send_data Checkout.output_checkoutlist_pdf(checkouts, params[:view]).generate, :filename => Setting.checkout_list_print_pdf.filename 
        end
      }
      format.tsv  { send_data Checkout.output_checkoutlist_csv(checkouts, params[:view]), :filename => Setting.checkout_list_print_tsv.filename }
      format.atom
    end
  end

  # GET /checkouts/1
  # GET /checkouts/1.json
  def show
    @checkout = Checkout.find(params[:id])
    if current_user.blank?
      access_denied; return
    end
    unless current_user.has_role?('Librarian')  
      unless current_user == @checkout.user
        access_denied; return
      end
    end

    respond_to do |format|
      format.html { render :template => 'opac/checkouts/show', :layout => 'opac' } if params[:opac]
      format.html # show.html.erb
      format.json { render :json => @checkout }
    end
  end

  # GET /checkouts/1/edit
  def edit
    @checkout = Checkout.find(params[:id])
    if current_user.blank?
      access_denied; return
    end
    unless current_user.has_role?('Librarian')
      unless current_user == @checkout.user
        access_denied; return
      end
    end

    @renew_due_date = @checkout.set_renew_due_date(@user)
    render :template => 'opac/checkouts/edit', :layout => 'opac' if params[:opac]
  end

  # PUT /checkouts/1
  # PUT /checkouts/1.json
  def update
    @checkout = Checkout.find(params[:id])
    if check_renewal(@checkout)
      @checkout.reload
      @checkout.checkout_renewal_count += 1

      respond_to do |format|
        if @checkout.update_attributes(params[:checkout])
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.checkout'))
          format.html { redirect_to user_checkout_url(@checkout.user, @checkout, :opac => true) } if params[:opac]
          format.html { redirect_to user_checkout_url(@checkout.user, @checkout) }
          format.json { head :no_content }
        else
          format.html { render :action => "edit", :template => "opac/checkouts/edit", :layout => 'opac' } if params[:opac]
          format.html { render :action => "edit" }
          format.json { render :json => @checkout.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /checkouts/1
  # DELETE /checkouts/1.json
  def destroy
    @checkout.destroy

    respond_to do |format|
      format.html { redirect_to user_checkouts_url(@checkout.user) }
      format.json { head :no_content }
    end
  end


  # for extend checkout term
  def extend
    @checkout = Checkout.new
  end

  def extend_checkout
    item = Item.find(:first, :conditions => {:item_identifier => params[:checkout][:item_identifier]})
    @checkout = Checkout.not_returned.where(:item_id => item.id).first
    if current_user.blank?
      access_denied; return
    end
    unless current_user.has_role?('Librarian')
      unless current_user == @checkout.user
        access_denied; return
      end
    end
  
    if check_renewal(@checkout)
      @checkout = @checkout.new_loan(current_user)
      @renewed = true

      render :edit
    end
    rescue Exception => e
      logger.error e
      
  end

  # PUT /batch_checkout
  def batchexec
    logger.info "batchexec start"
    status = nil
    unless admin_networks?
      logger.error "invalid access network"
      status = {'code' => 900, 'note' => 'invalid access network'}
    end

    #Parameters: {"id"=>"3", "user_number"=>"nakamura", "item_identifier"=>"JX009", "created_at"=>"20121026144222"}
    if params[:id].blank? || params[:user_number].blank? || params[:item_identifier].blank? || params[:created_at].blank?
      logger.error "invalid parameter error."
      status = {'code' => 800, 'note' => 'invalid parameter error'}
    end

    unless status
      status = batchexec_checkout(params)
    end

    logger.info "batchexec status=#{status['code']}"
    render :text => status.values.join("\t"), :status => 200
  end

private
  def batchexec_checkout(params)
    status = {}

    checked_item = {"item_identifier"=>params[:item_identifier], "ignore_restriction"=>"1"}
    logger.debug "basket create."
    basket = Basket.new
    basket.user_number = params[:user_number]

    logger.debug "user check."
    user = User.where(:user_number => basket.user_number.strip).first rescue nil
    unless user
      logger.debug "invalid user"
      status = {'code' => 200, 'note' => 'invalid user_number'}
      return status
    end
    basket.user = user
    basket.save

    logger.debug "checked item create"
    checked_item = CheckedItem.new(checked_item)
    checked_item.basket = basket

    item_identifier = checked_item.item_identifier.to_s.strip

    logger.debug "check item_identifier #{item_identifier}"
    item = Item.where(:item_identifier => item_identifier).first 
    unless item
      logger.error "item no record"
      status = {'code' => 300, 'note' => 'invalid item_identifier'}
      return status
    end
    checked_item.item = item if item

    logger.debug "checked item save start"
    if checked_item.save
      logger.info "success checkout"
      status = {'code' => 0}
    else
      rmsg = ""
      logger.info "unsuccess checkout"
      checked_item.errors do |attr, msg|
        rmsg = msg 
      end
      status = {'code' => 100, 'msg' => rmsg}
    end
   
    return status
  end

  def check_renewal(checkout)
    if checkout.reserved?
      flash[:notice] = t('checkout.this_item_is_reserved')
      redirect_to edit_user_checkout_url(@checkout.user, @checkout)
      return false
    end
    if checkout.available_for_extend #checkout.over_checkout_renewal_limit?
      flash[:notice] = t('checkout.excessed_renewal_limit')
      unless current_user.has_role?('Librarian')
        redirect_to edit_user_checkout_url(@checkout.user, @checkout)
        return false
      end
    end
    if checkout.overdue?
      flash[:notice] = t('checkout.you_have_overdue_item')
      unless current_user.has_role?('Librarian')
        redirect_to edit_user_checkout_url(@checkout.user, @checkout)
        return false
      end
    end
    return true
  end
end

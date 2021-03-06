class Checkout < ActiveRecord::Base
  self.extend ItemsHelper
  attr_accessible :librarian_id, :item_id, :basket_id, :due_date, :created_at
  default_scope :order => 'due_date ASC, id DESC'#:order => 'id DESC'
  scope :not_returned, where(:checkin_id => nil)
  scope :overdue, lambda {|date| {:conditions => ['checkin_id IS NULL AND due_date < ?', date]}}
  scope :due_date_on, lambda {|date| where(:checkin_id => nil, :due_date => date.beginning_of_day .. date.end_of_day)}
  scope :completed, lambda {|start_date, end_date| {:conditions => ['created_at >= ? AND created_at < ?', start_date, end_date]}}
  scope :on, lambda {|date| {:conditions => ['created_at >= ? AND created_at < ?', date.beginning_of_day, date.tomorrow.beginning_of_day]}}

  belongs_to :user #, :counter_cache => true #, :validate => true
  delegate :username, :user_number, :to => :user, :prefix => true
  belongs_to :item #, :counter_cache => true #, :validate => true
  belongs_to :checkin #, :validate => true
  belongs_to :librarian, :class_name => 'User' #, :validate => true
  belongs_to :basket #, :validate => true
  has_many :reminder_list
  has_many :events

  validates_associated :user, :item, :librarian, :checkin #, :basket
  # TODO: 貸出履歴を保存しない場合は、ユーザ名を削除する
  #validates_presence_of :user, :item, :basket
  validates_presence_of :item_id, :basket_id, :due_date, :checked_at, :checkout_renewal_count
  validates_uniqueness_of :item_id, :scope => [:basket_id, :user_id]
  validate :is_not_checked?, :on => :create
  validates_date :due_date, :allow_blank => true
  validate :check_due_date
  after_create :store_history

  attr_accessor :item_identifier
  attr_accessible :user_id, :checkout_renewal_count, :available_for_extend, :checked_at

  paginates_per 10

  def user_group_has_checkout_type
    UserGroupHasCheckoutType.where(user_group_id: user.user_group_id, checkout_type_id: item.checkout_type_id).first
  end

  # TODO (method name)
  def days_overdue
    number_of_delay = user_group_has_checkout_type.days_overdue
    due_date = self.due_date.localtime.to_date
    diff = Date.today - (due_date + number_of_delay.days)
    diff_i = diff.to_i
    if diff_i < 0
      diff_i = 0
    end
    return diff_i
  end

  def day_of_overdue
    due_date_datetype = due_date.strftime("%Y-%m-%d")
    overdue = (Date.today - due_date_datetype.to_date) 
    overdue = 0 if overdue < 0
    return overdue.to_i
  end

  def is_not_checked?
    checkout = Checkout.not_returned.where(:item_id => self.item.id) rescue nil
    unless checkout.empty?
      errors[:base] << I18n.t('activerecord.errors.messages.checkin.already_checked_out') unless SystemConfiguration.get('checkout.auto_checkin')
    end
  end

  def checkout_renewable?(current_user)
    return false if self.overdue?
    if self.item
      unless current_user.has_role?('Librarian')
        return false if self.over_checkout_renewal_limit? 
      end
      return false if !available_for_extend  # && !current_user.has_role?('Librarian')
      return false if self.reserved?
    end
    true
    rescue Exception => e
      false
  end

  def reserved?
    return true if self.item.reserved?
  end

  def over_checkout_renewal_limit?
    return true if self.item.checkout_status(self.user).checkout_renewal_limit <= self.checkout_renewal_count
    return false
  end

  def overdue?
#    if Time.zone.now.tomorrow.beginning_of_day >= self.due_date
    if Time.zone.now.beginning_of_day > self.due_date
      return true
    else
      return false
    end
  end

  def exist_reminder_list?
    return false if ReminderList.where(:checkout_id => self.id).blank?
    return true
  end

  def is_today_due_date?
    if Time.zone.now.beginning_of_day == self.due_date.beginning_of_day
      return true
    else
      return false
    end
  end

  def set_renew_due_date(user)
    if self.item
      if self.available_for_extend # self.checkout_renewal_count <= self.item.checkout_status(user).checkout_renewal_limit
        renew_due_date = self.due_date.advance(:days => self.item.checkout_status(user).checkout_period)
        # 返却期限日が閉館日の場合
        while self.item.shelf.library.closed?(renew_due_date)
          checkin_before = false 
          self.item.shelf.library.events.closing_days.each do |e|
            if e.start_at.beginning_of_day <= renew_due_date.beginning_of_day && e.end_at.end_of_day >= renew_due_date.beginning_of_day
              checkin_before = true if e.event_category.move_checkin_date == 2
            end
          end
          if checkin_before
            renew_due_date = renew_due_date.yesterday.end_of_day
          elsif self.item.checkout_status(user).set_due_date_before_closing_day
            renew_due_date = renew_due_date.yesterday.end_of_day
          else
            renew_due_date = renew_due_date.tomorrow.end_of_day
          end
        end
      else
        renew_due_date = self.due_date
      end
      return renew_due_date
    end
  end

  def check_due_date
    if self.due_date <= Time.zone.now
      errors[:base] = I18n.t('activerecord.errors.messages.checkout.invalid_date')
      return false
    end
    return true
  end

  def new_loan(user)
    Checkout.transaction do
      new_basket = Basket.create(:user_id => self.user.id)
      new_basket.checked_items.create(:item_id => self.item_id)
      new_basket.basket_checkout(user) # checkout
      new_checkout = Checkout.where(:basket_id => new_basket.id).first
      new_checkout.checkout_renewal_count = self.checkout_renewal_count + 1
      new_checkout.available_for_extend = user.has_role?('Librarian')
      new_checkout.save
      return new_checkout
    end
    return self
  end

  def self.manifestations_count(start_date, end_date, manifestation)
    self.completed(start_date, end_date).where(:item_id => manifestation.items.collect(&:id)).count
  end

  def self.send_due_date_notification
    template = 'recall_item'
    queues = []
    User.find_each do |user|
      # 未来の日時を指定する
      checkouts = user.checkouts.due_date_on(user.user_group.number_of_day_to_notify_due_date.days.from_now.beginning_of_day)
      unless checkouts.empty?
        if SystemConfiguration.get("send_message.recall_item")
          queues << user.send_message(template, :manifestations => checkouts.collect(&:item).collect(&:manifestation))
        end
      end
    end
    queues.size
  end

  def self.send_overdue_notification
    template = 'recall_overdue_item'
    queues = []
    User.find_each do |user|
      user.user_group.number_of_time_to_notify_overdue.times do |i|
        checkouts = user.checkouts.due_date_on((user.user_group.number_of_day_to_notify_overdue * (i + 1)).days.ago.beginning_of_day)
        unless checkouts.empty?
          if SystemConfiguration.get("send_message.recall_overdue_item")
            queues << user.send_message(template, :manifestations => checkouts.collect(&:item).collect(&:manifestation))
            checkouts.each do |checkout|
              ReminderList.where(:checkout_id => checkout.id).update_all(:status => 1, :mail_sent_at => Time.zone.now) rescue nil
            end
          end
        end
      end
    end
    queues.size
  end

  def self.apend_to_reminder_list
    queues_size = 0 
    User.find_each do |user|
      user.user_group.number_of_time_to_notify_overdue.times do |i|
        checkouts = user.checkouts.due_date_on((user.user_group.number_of_day_to_notify_overdue * (i + 1)).days.ago.beginning_of_day)
        unless checkouts.empty?
          checkouts.each do |checkout|
            #logger.info checkout
            queues_size += checkout.add_to_reminder_list
          end
        end
      end
    end

    queues_size
  end

  def add_to_reminder_list
    r = ReminderList.where(:checkout_id => self.id)
    if r.blank?
      r = ReminderList.new
      r.checkout_id = self.id
      r.status = 0
      r.save!
      logger.info "create ReminderList checkout_id=#{self.id}"
      return 1
    end
    return 0
  end

  # output
  def self.output_checkouts(checkouts, user, current_user)
    unless SystemConfiguration.get("checkout.set_rental_certificate_size") == true
      report = EnjuTrunkCirculation.new_report('checkouts_A4.tlf')
    else
      report = EnjuTrunkCirculation.new_report('checkouts.tlf')
    end

    report.layout.config.list(:list) do
      use_stores :total => 0
      events.on :footer_insert do |e|
        e.section.item(:total).value(checkouts.size)
        e.section.item(:message).value(SystemConfiguration.get("checkouts_print.message"))
      end
    end

    library = Library.find(current_user.library_id) rescue nil

    report.start_new_page do |page|
      page.item(:library).value(LibraryGroup.system_name(@locale))
      page.item(:user).value(user.user_number)
      page.item(:full_name).value(user.agent.full_name) unless SystemConfiguration.get("checkout.set_rental_certificate_size")
      page.item(:lend_user).value(current_user.user_number)
      page.item(:lend_library).value(library.display_name)
      page.item(:lend_library_telephone_number_1).value(library.telephone_number_1)
      page.item(:lend_library_telephone_number_2).value(library.telephone_number_2)
      page.item(:date).value(checkouts.first.checked_at.strftime('%Y/%m/%d'))

      checkouts.each do |checkout|
        page.list(:list).add_row do |row|
          row.item(:book).value(checkout.item.manifestation.original_title)
          row.item(:due_date).value(checkout.due_date)
        end
      end
    end
    return report
  end

  def self.output_checkoutlist_pdf(checkouts, view)
    report = EnjuTrunkCirculation.new_report('checkoutlist.tlf')

    # set page_num
    report.events.on :page_create do |e|
      e.page.item(:page).value(e.page.no)
    end
    report.events.on :generate do |e|
      e.pages.each do |page|
        page.item(:total).value(e.report.page_count)
      end
    end

    report.start_new_page do |page|
      page.item(:date).value(Time.now)
      if view == 'overdue'
        page.item(:page_title).value(I18n.t('checkout.listing_overdue_item'))
      else
        page.item(:page_title).value(I18n.t('page.listing', :model => I18n.t('activerecord.models.checkout')))
      end

      if checkouts.size == 0
        page.list(:list).add_row do |row|
          row.item(:not_found).show
          row.item(:not_found).value(I18n.t('page.no_record_found'))
          (1..7).each do |i|
            row.item("line#{i}").hide
          end
        end
      else
        checkouts.each do |checkout|
          page.list(:list).add_row do |row|
            row.item(:not_found).hide
            user = checkout.user.agent.full_name
            if SystemConfiguration.get("checkout_print.old") == true and checkout.user.agent.date_of_birth
              age = (Time.now.strftime("%Y%m%d").to_f - checkout.user.agent.date_of_birth.strftime("%Y%m%d").to_f) / 10000
              age = age.to_i
              user = user + '(' + age.to_s + I18n.t('activerecord.attributes.agent.old')  +')'
            end
            row.item(:user).value(user)
            row.item(:title).value(checkout.item.manifestation.original_title)
            row.item(:item_identifier).value(checkout.item.item_identifier)
            row.item(:library).value(checkout.item.shelf.library.display_name.localize)
            row.item(:shelf).value(checkout.item.shelf.display_name.localize)
            row.item(:due_date).value(checkout.due_date.strftime("%Y/%m/%d"))
            renewal_count = checkout.checkout_renewal_count.to_s + '/' + checkout.item.checkout_status(checkout.user).checkout_renewal_limit.to_s
            row.item(:renewal_count).value(renewal_count)
            due_date_datetype = checkout.due_date.strftime("%Y-%m-%d")
            overdue = Date.today - due_date_datetype.to_date
            overdue = 0 if overdue < 0
            row.item(:overdue).value(overdue)
          end
        end
      end
     end
    return report
  end

  def self.output_checkoutlist_csv(checkouts, view)
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8") + "\n"
    columns = [
      [:user,'activerecord.models.user'],
      [:title, 'activerecord.attributes.manifestation.original_title'],
      [:item_identifier,'activerecord.attributes.item.item_identifier'],
      [:library, 'activerecord.models.library'],
      [:shelf, 'activerecord.models.shelf'],
      [:due_date, 'activerecord.attributes.checkout.due_date'],
      [:renewal_count, 'activerecord.attributes.checkout.renewal_count'],
      [:overdue, 'checkout.number_of_day_overdue'],
    ]

    # title column
    row = columns.map {|column| I18n.t(column[1])}
    data << '"'+row.join("\"\t\"")+"\"\n"

    # set
    checkouts.each do |checkout|
      row = []
      columns.each do |column|
        case column[0]
        when :user
          user = checkout.user.agent.full_name
          if SystemConfiguration.get("reserve_print.old") == true and  checkout.user.agent.date_of_birth
            age = (Time.now.strftime("%Y%m%d").to_f - checkout.user.agent.date_of_birth.strftime("%Y%m%d").to_f) / 10000
            age = age.to_i
            user = user + '(' + age.to_s + I18n.t('activerecord.attributes.agent.old')  +')'
          end
          row << user
        when :title
          row << checkout.item.manifestation.original_title 
        when :item_identifier
          row << checkout.item.item_identifier
        when :library
          row << checkout.item.shelf.library.display_name.localize
        when :shelf
          row << checkout.item.shelf.display_name.localize
        when :due_date
          row << checkout.due_date.strftime("%Y/%m/%d")
        when :renewal_count
          renewal_count = checkout.checkout_renewal_count.to_s + '/' + checkout.item.checkout_status(checkout.user).checkout_renewal_limit.to_s
          row << renewal_count
        when :overdue
          due_date_datetype = checkout.due_date.strftime("%Y-%m-%d")
          overdue = Date.today - due_date_datetype.to_date
          overdue = 0 if overdue < 0
          row << overdue
        end
      end
      data << '"'+row.join("\"\t\"")+"\"\n"
    end 
    return data
  end

  def self.get_checkoutlists_pdf(displist)
    report = EnjuTrunkCirculation.new_report('circulation_status_list.tlf')

    # set page_num
    report.events.on :page_create do |e|
      e.page.item(:page).value(e.page.no)
    end
    report.events.on :generate do |e|
      e.pages.each do |page|
        page.item(:total).value(e.report.page_count)
      end
    end
    # set items
    report.start_new_page do |page|
      page.item(:date).value(Time.now)
      before_status = nil
      displist.each do |d|
        unless d.items.blank?
          d.items.each do |item|
            page.list(:list).add_row do |row|
              if before_status == d.circulation_status
               row.item(:status_line).hide
               row.item(:status).hide
              end
              row.item(:status).value(d.circulation_status)
              row.item(:title).value(item.manifestation.original_title)
              row.item(:library).value(item.shelf.library.display_name)
              row.item(:shelf).value(item.shelf.display_name.localize)
              row.item(:call_number).value(call_numberformat(item)) if item.call_number
              row.item(:identifier).value(item.item_identifier) if item.item_identifier
            end
            before_status = d.circulation_status
          end
        else
          page.list(:list).add_row do |row|
            row.item(:status).value(d.circulation_status)
            row.item(:title).value(I18n.t('page.no_record_found'))
            row.item(:line2).hide
            row.item(:line3).hide
            row.item(:line4).hide
            row.item(:line5).hide
          end
        end
      end
    end
    return report
  end

  def self.get_checkoutlists_tsv(displist)
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8") + "\n"
    columns = [
      [:title,           'activerecord.attributes.manifestation.original_title'],
      [:library,         'activerecord.models.library'],
      [:shelf,           'activerecord.models.shelf'],
      [:call_number,     'activerecord.attributes.item.call_number'],
      [:item_identifier, 'activerecord.attributes.item.item_identifier'],
    ]

    displist.each do |d|
      data << '"'+d.circulation_status+"\"\n"
      row = columns.map { |column| I18n.t(column[1]) }
      data << '"'+row.join("\"\t\"")+"\"\n"
      d.items.each do |item|
        row = []
        columns.each do |column|
          case column[0]
          when :title
            row << item.manifestation.original_title 
          when :library
            row << item.shelf.library.display_name
          when :shelf
            row << item.shelf.display_name.localize
          when :call_number
            row << call_numberformat(item) if item.call_number
          when :item_identifier
            row << item.item_identifier if item.item_identifier
          end
        end
        data << '"'+row.join("\"\t\"")+"\"\n"
      end
      data << "\n"
    end
    return data
  end

  def self.get_checkoutlists_excel(current_user, checkouts)
    header = [I18n.t('activerecord.attributes.user.username'),
              I18n.t('activerecord.attributes.user.full_name'),
              I18n.t('activerecord.attributes.user.user_group'),
              I18n.t('activerecord.attributes.user.department')]
    header << I18n.t('activerecord.attributes.agent.grade') if SystemConfiguration.get('agent.manage_grade')
    header << I18n.t('activerecord.attributes.item.identifier') if SystemConfiguration.get('item.use_different_identifier')
    header << I18n.t('activerecord.attributes.item.item_identifier')
    header << I18n.t('activerecord.attributes.item.call_number')
    header << I18n.t('activerecord.attributes.manifestation.original_title')
    header << I18n.t('activerecord.attributes.manifestation.creator')
    header << I18n.t('activerecord.attributes.checkout.checked_at')

    rows = []
    checkouts.each do |checkout|
      row = []
      row << checkout.try(:user).try(:username) || ''
      row << checkout.try(:user).try(:agent).try(:full_name) || ''
      row << checkout.try(:user).try(:user_group).try(:display_name) || ''
      row << checkout.try(:user).try(:department).try(:display_name) || ''
      row << checkout.try(:user).try(:agent).try(:grade).try(:keyname) || '' if SystemConfiguration.get('agent.manage_grade')
      row << checkout.try(:item).try(:identifier) || '' if SystemConfiguration.get('item.use_different_identifier')
      row << checkout.try(:item).try(:item_identifier) || ''
      row << checkout.try(:item).try(:call_number) || ''
      row << checkout.try(:item).try(:manifestation).try(:original_title) || ''
      creators = checkout.try(:item).try(:manifestation).try(:creators)
      row << (creators.blank? ? '' : creators.map(&:full_name).join(','))
      row << checkout.try(:checked_at).try(:strftime, '%Y-%m-%d') || ''
       
      rows << row
    end
    
    filename = I18n.t('page.listing', :model => I18n.t('activerecord.models.checkout')) + '.xlsx'
    return CreateExportFile.create_export_file(current_user, filename, header, rows)
  end
 
  def store_history
    if checkout_renewal_count == 0
      CheckoutHistory.store_history("checkout", self)
    else
      CheckoutHistory.store_history("extend", self)
    end
  end

  def self.ouput_columns
    return [{name:"username", model: "user", column: "username"},
            {name:"full_name", model: "agent", column: "full_name"},
            {name:"grade", model: "keycode", column: "keyname"},
            {name:"user_number", model: "user", column: "usernumber"},
            {name:"user_group", model: "user_group", column: "display_name"},
            {name:"department", model: "department", column: "display_name"},
            {name:"original_title", model: "manifestation", column: "original_title"},
            {name:"creator", model: "calculate", column: "calculate"},
            {name:"call_number", model: "item", column: "call_number"},
            {name:"identifier", model: "item", column: "identifier"},
            {name:"item_identifier", model: "item", column: "item_identifier"},
            {name:"location_category", model: "location_category", column: "display_name"},
            {name:"due_date", model: "checkout", column: "due_date"},
            {name:"reserve", model: "calculate", column: "calculate"},
           ]
  end

  def self.output_checkoutlist_excelx(checkouts, params)
    require 'axlsx'

    # initialize
    out_dir = "#{Rails.root}/private/system/checkouts_excelx"
    excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{rand(10)}.xlsx"
    FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)

    logger.info "output_checkoutlist_excelx filepath=#{excel_filepath}"

    # 出力データ
    if params[:ouput_columns].present?
      header = []
      details = []
      params[:ouput_columns].each do |name|
        name_ja = I18n.t("checkout_output_excel.#{name}")
        header << name_ja
      end
      
      checkouts.each.with_index(1) do |checkout, index|
        detail = []
        params[:ouput_columns].each do |name|
          ouput_column = self.ouput_columns.find{|ouput_column| ouput_column[:name] == name }
          model = ouput_column[:model]
          column = ouput_column[:column]
          case name
            when "username"
              detail << (checkout.user.present? ? checkout.user.username : "")
            when "full_name"
              detail << (checkout.user.agent.present? ? checkout.user.agent.full_name : "")
            when "grade"
              detail << (checkout.user.agent.grade.present? ? checkout.user.agent.grade.keyname : "")
            when "user_number"
              detail << (checkout.user.present? ? checkout.user.user_number : "")
            when "user_group"
              detail << (checkout.user.user_group.present? ? checkout.user.user_group.display_name : "")
            when "department"
              detail << (checkout.user.department.present? ? checkout.user.department.display_name : "")
            when "original_title"
              detail << (checkout.item.manifestation.present? ? checkout.item.manifestation.original_title : "")
            when "creator"
              if checkout.item.manifestation.creators.present?
                creators = checkout.item.manifestation.creators.map(&:full_name).join(";")
              else
                creators = ""
              end
              detail << creators
            when "call_number"
              detail << (checkout.item.present? ? checkout.item.call_number : "")
            when "identifier"
              detail << (checkout.item.present? ? checkout.item.identifier : "")
            when "item_identifier"
              detail << (checkout.item.present? ? checkout.item.item_identifier : "")
            when "location_category"
              detail << (checkout.item.location_category.present? ? checkout.item.location_category.keyname : "")
            when "due_date"
              detail << (checkout.due_date.present? ? checkout.due_date.to_date : "")
            when "reserve"
              if checkout.item.manifestation.reserves.present?
                reserve = I18n.t("checkout_output_excel.reserved")
              else
                reserve = I18n.t("checkout_output_excel.nonreserve")
              end
              detail << reserve
          end
        end
        details << detail
      end

    end

    Axlsx::Package.new do |p|
      wb = p.workbook
      wb.styles do |s|
        sheet = wb.add_worksheet(:name => I18n.t('checkout_output_excel.checkout_list'))
        default_style = s.add_style :font_name => Setting.checkout_list_print_xlsx.fontname
        # ヘッダ部
        if header.present?
          sheet.add_row header, :types => :string, :style => default_style
        end
        # データ部分
        if details.present?
          details.each do |detail|
            sheet.add_row detail, :types => :string, :style => default_style
          end
        end
        p.serialize(excel_filepath)
      end
    end
    return excel_filepath
  end

end

# == Schema Information
#
# Table name: checkouts
#
#  id                     :integer         not null, primary key
#  user_id                :integer
#  item_id                :integer         not null
#  checkin_id             :integer
#  librarian_id           :integer
#  basket_id              :integer
#  due_date               :datetime
#  checkout_renewal_count :integer         default(0), not null
#  lock_version           :integer         default(0), not null
#  created_at             :datetime
#  updated_at             :datetime
#


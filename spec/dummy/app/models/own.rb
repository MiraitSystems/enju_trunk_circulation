class Own < ActiveRecord::Base
  belongs_to :agent #, :counter_cache => true #, :polymorphic => true, :validate => true
  belongs_to :item #, :counter_cache => true #, :validate => true

  validates_associated :agent, :item
  validates_presence_of :agent, :item
  validates_uniqueness_of :item_id, :scope => :agent_id
  after_save :reindex
  after_destroy :reindex

  acts_as_list :scope => :item

  paginates_per 10
  attr_accessor :item_identifier

  def reindex
    agent.try(:index)
    item.try(:index)
  end
end

# == Schema Information
#
# Table name: owns
#
#  id         :integer         not null, primary key
#  agent_id  :integer         not null
#  item_id    :integer         not null
#  position   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#


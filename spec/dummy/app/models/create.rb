require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'create')
class Create < ActiveRecord::Base
  belongs_to :agent

  validates_associated :agent
  after_save :reindex
  after_destroy :reindex

  paginates_per 10

  has_paper_trail

  def reindex
    agent.try(:index)
    work.try(:index)
  end
end

# == Schema Information
#
# Table name: creates
#
#  id         :integer         not null, primary key
#  agent_id  :integer         not null
#  work_id    :integer         not null
#  position   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#


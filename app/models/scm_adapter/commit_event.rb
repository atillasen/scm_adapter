# frozen_string_literal: true
class ScmAdapter::CommitEvent < ActiveRecord::Base
  self.table_name = "scm_adapter_commit_events"

  belongs_to :issue
  belongs_to :deleted_by, class_name: "User", optional: true

  validates :issue_id, presence: true
  validates :provider, presence: true

  scope :active, -> { where(deleted_at: nil) }
end

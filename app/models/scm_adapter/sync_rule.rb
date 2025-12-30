# frozen_string_literal: true
class ScmAdapter::SyncRule < ActiveRecord::Base
  self.table_name = "scm_adapter_sync_rules"

  belongs_to :project, optional: true

  # Columns are JSON/JSONB in DB; no ActiveRecord serialize needed

  validates :issue_status_mapping, presence: true
end

# frozen_string_literal: true
class ScmAdapter::ProjectLink < ActiveRecord::Base
  self.table_name = "scm_adapter_project_links"

  belongs_to :project

  validates :project_id, presence: true
  validates :provider, inclusion: { in: %w[gitlab github] }
  validates :remote_project_id, presence: true
  validates :remote_full_path, presence: true

  after_save :sync_mirror_and_repository!, if: :mirror_attributes_changed?

  private

  def mirror_attributes_changed?
    saved_change_to_provider? ||
      saved_change_to_remote_full_path? ||
      saved_change_to_remote_project_id? ||
      saved_change_to_project_id? ||
      saved_change_to_id?
  end

  def sync_mirror_and_repository!
    return if ENV["SCM_ADAPTER_SKIP_MIRROR_SYNC"].to_s == "1"

    ScmAdapter::MirrorSyncJob.new.perform(
      project_id: project_id,
      provider: provider,
      remote_full_path: remote_full_path,
      remote_project_id: remote_project_id
    )
  rescue StandardError => e
    errors.add(:base, "Mirror-Sync fehlgeschlagen: #{e.message}")
    raise ActiveRecord::Rollback, e
  end
end

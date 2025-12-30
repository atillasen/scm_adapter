# frozen_string_literal: true
module ScmAdapter
  class CommitEventsController < ApplicationController
    before_action :find_event
    before_action :authorize_project

    def confirm
      # Renders form for deletion reason
    end

    def destroy
      reason = params[:reason].to_s.strip
      if reason.blank?
        render status: :unprocessable_entity, plain: I18n.t("scm_adapter.errors.reason_required") and return
      end

      issue = @event.issue
      @event.update!(deleted_at: Time.current, deleted_by: User.current, deletion_reason: reason)

      sha_short = @event.sha.to_s[0, 8]
      note = I18n.t(
        "scm_adapter.journal.commit_hidden",
        sha: sha_short,
        provider: @event.provider,
        reason: reason
      )
      issue.init_journal(User.current, note)
      issue.save!(validate: false)
      flash[:notice] = I18n.t("scm_adapter.flashes.commit_hidden")
      redirect_to issue_path(issue)
    end

    private

    def find_event
      @event = ScmAdapter::CommitEvent.find(params[:id])
      @project = @event.issue.project
    end

    def authorize_project
      deny_access unless User.current.allowed_to?(:manage_repository, @project)
    end
  end
end

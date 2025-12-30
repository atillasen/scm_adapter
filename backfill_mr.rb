settings = Setting.plugin_scm_adapter.to_h
allowed = settings["close_keywords"]
allowed = Array(allowed.presence || %w[fixes closes resolves]).map(&:downcase)
parser = ScmAdapter::Sync::CloseKeywordParser.new(allowed_keywords: allowed)

link = ScmAdapter::ProjectLink.find_by(provider: "gitlab")
if link.nil?
  puts "No gitlab project link found"
  exit 0
end

client = ScmAdapter::Clients::GitlabClient.new(base_url: settings["gitlab_base_url"], token: settings["gitlab_token"])
mrs = client.list_merge_requests(link.remote_project_id, { state: "all", per_page: 50 })
created = 0

mrs.each do |mr|
  text = mr["description"].to_s
  issue_ids = parser.extract_issue_ids(text)
  next if issue_ids.empty?

  issue_ids.each do |iid|
    issue = Issue.find_by(id: iid, project_id: link.project_id)
    next unless issue
    existing = ScmAdapter::CommitEvent.where(issue_id: issue.id, provider: "gitlab", merge_request_iid: mr["iid"].to_s).first
    next if existing

    ScmAdapter::CommitEvent.create!(
      issue_id: issue.id,
      provider: "gitlab",
      sha: mr["sha"] || mr["merge_commit_sha"] || mr.dig("head_pipeline", "sha") || mr.dig("last_commit", "id"),
      author: mr.dig("author", "name"),
      url: mr["web_url"] || mr["url"],
      message: text,
      pushed_at: mr["updated_at"] || mr["created_at"],
      branch: mr["source_branch"],
      merge_request_title: mr["title"],
      merge_request_url: mr["web_url"] || mr["url"],
      merge_request_iid: mr["iid"].to_s
    )
    created += 1
  end
end

puts "Backfill created #{created} MR events"

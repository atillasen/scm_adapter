# frozen_string_literal: true
require "faraday"
require "faraday/retry"
require "multi_json"

module ScmAdapter
  module Clients
    class GitlabClient
      def initialize(base_url:, token:, webhook_secret: nil)
        @base_url = base_url.chomp("/")
        @token    = token
        @secret   = webhook_secret
        # Allow opting out of SSL verification or providing a custom CA for self-signed GitLab instances
        ssl_verify  = ENV.fetch("SCM_ADAPTER_SSL_VERIFY", "true") != "false"
        ssl_options = { verify: ssl_verify }
        ca_file     = ENV["SCM_ADAPTER_CA_FILE"]
        ssl_options[:ca_file] = ca_file if ca_file.present?

        @http     = Faraday.new(url: @base_url, ssl: ssl_options) do |f|
          f.request :retry, max: 2, interval: 0.1, backoff_factor: 2
          f.request :json
          f.response :json, content_type: /\bjson$/
          f.adapter Faraday.default_adapter
          f.headers["Private-Token"] = @token if @token.present?
          f.headers["User-Agent"] = "scm_adapter/1.0"
        end
      end

      def project(project_id_or_path)
        get_json("/api/v4/projects/#{url_escape(project_id_or_path)}")
      end

      def list_projects(params = {})
        get_json("/api/v4/projects", params)
      end

      def list_merge_requests(project_id, params = {})
        get_json("/api/v4/projects/#{project_id}/merge_requests", params)
      end

      def list_issues(project_id, params = {})
        get_json("/api/v4/projects/#{project_id}/issues", params)
      end

      def post_comment(project_id, issue_iid, body)
        post_json("/api/v4/projects/#{project_id}/issues/#{issue_iid}/notes", { body: body })
      end

      def post_commit_comment(project_id, sha, body)
        post_json("/api/v4/projects/#{project_id}/repository/commits/#{url_escape(sha)}/comments", { note: body })
      end

      def list_commit_comments(project_id, sha, params = {})
        get_json("/api/v4/projects/#{project_id}/repository/commits/#{url_escape(sha)}/comments", params)
      end

      private

      def get_json(path, params = {})
        res = @http.get(path, params)
        handle_response(res)
      end

      def post_json(path, payload = {})
        res = @http.post(path) { |r| r.body = payload }
        handle_response(res)
      end

      def handle_response(res)
        if res.success?
          res.body
        else
          raise "GitLab API Error: #{res.status} #{res.body}"
        end
      end

      def url_escape(val)
        CGI.escape(val.to_s)
      end
    end
  end
end


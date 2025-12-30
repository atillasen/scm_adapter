# frozen_string_literal: true
require "faraday"
require "faraday/retry"
require "multi_json"

module ScmAdapter
  module Clients
    class GithubClient
      def initialize(base_url: "https://api.github.com", token:, webhook_secret: nil)
        @base_url = base_url.chomp("/")
        @token    = token
        @secret   = webhook_secret
        @http     = Faraday.new(url: @base_url) do |f|
          f.request :retry, max: 2, interval: 0.1, backoff_factor: 2
          f.request :json
          f.response :json, content_type: /\bjson$/
          f.adapter Faraday.default_adapter
          f.headers["Authorization"] = "Bearer #{@token}" if @token.present?
          f.headers["Accept"]        = "application/vnd.github+json"
          f.headers["User-Agent"]    = "scm_adapter/1.0"
        end
      end

      def repo(full_name) # "owner/repo"
        get_json("/repos/#{full_name}")
      end

      def issues(full_name, params = {})
        get_json("/repos/#{full_name}/issues", params)
      end

      def pulls(full_name, params = {})
        get_json("/repos/#{full_name}/pulls", params)
      end

      def post_issue_comment(full_name, issue_number, body)
        post_json("/repos/#{full_name}/issues/#{issue_number}/comments", { body: body })
      end

      def post_commit_comment(full_name, sha, body)
        post_json("/repos/#{full_name}/commits/#{sha}/comments", { body: body })
      end

      def list_commit_comments(full_name, sha, params = {})
        get_json("/repos/#{full_name}/commits/#{sha}/comments", params)
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
          raise "GitHub API Error: #{res.status} #{res.body}"
        end
      end
    end
  end
end

require 'rugged'
require 'securerandom'

module Anonydog
  class Local
    # Anonymizes a commit chain (head) for merging into another (base) chain.
    # Returns a Rugged::Repository where HEAD is the anonymized branch.
    #
    # Params:
    # :head => {
    #   :clone_url => URL for the repo containing the head commit,
    #   :commit => SHA-1 identifier for the head commit}
    #
    # :base => {
    #   :clone_url => URL for the repo containing the base commit,
    #   :commit => SHA-1 identifier for the base commit}
    def self.anonymize(opts)
      head_repo_clone_url = opts[:head][:clone_url]
      head_commit = opts[:head][:commit]

      base_repo_clone_url = opts[:base][:clone_url]
      base_commit = opts[:base][:commit]

      #TODO: use in-memory backend (Rugged::InMemory::Backend)
      repo_path = "/tmp/#{SecureRandom.hex}"

      repo = Rugged::Repository.clone_at(
        head_repo_clone_url,
        repo_path)

      repo.remotes.create('upstream', base_repo_clone_url)
      repo.fetch('upstream')

      new_head = merge_base = repo.merge_base(head_commit, base_commit)

            Rugged::Walker.walk(
        repo,
        :sort => Rugged::SORT_TOPO | Rugged::SORT_REVERSE, # parents first
        :show => head_commit,
        :hide => merge_base) {
        |commit|
          fake_author_sig = {
            :name => 'Scooby Doo',
            :email => 'scooby@anonydog.org',
            :time => commit.author[:time]
          }

          current = Rugged::Commit.create(
            repo,
            :message => commit.message,
            :tree => commit.tree,
            # TODO: check for unintended side-effects here
            :committer => fake_author_sig,
            #TODO: inside a PR, can a commit have more than one parent?
            :parents => [new_head],
            :author => fake_author_sig
          )

          new_head = current
      }

      branch = repo.branches.create("pullrequest-#{SecureRandom.hex(4)}", new_head)
      repo.head = "refs/heads/#{branch.name}"
      repo
    end

    # Publishes HEAD ref/branch from a rugged repository to a remote (github)
    # repo.
    def self.publish(local_repo, remote_repo_url)
      creds = Rugged::Credentials::SshKey.new(
        publickey: File.expand_path("~/.ssh/bot.pub"),
        privatekey: File.expand_path("~/.ssh/bot"),
        username: 'git')

      remote = local_repo.remotes.create_anonymous(remote_repo_url)

      remote.push([local_repo.head.name], {credentials: creds})
    end
  end
end
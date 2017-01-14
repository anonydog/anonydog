require 'rugged'
require 'securerandom'

head_repo_clone_url = 'https://github.com/anonydog/testing-contributor_repo.git'
base_repo_clone_url = 'https://github.com/anonydog/testing-maintainer_repo.git'

# repo layout for reference
#
#   maintainer/
#     master    contributor
#       |        /
#  c118 o       o 1c1c
#       |      /
#       |     /
#       |    o
#       |   /
#       |  o
#       | /
#       |/
#  4879 o

# TODO: convert these into proper tests

# simple fast-forward pull request
base_commit = '487958f50bc90109f3b1ed89701894b1fe5a03ee'
tip_commit = '1c1ccfe285676856ae719d27e9e90aaff23d42db'
#
# non-fast-forward pull request
base_commit = 'c118828dd9d5669da9755a03b03f1a240a71864d'
tip_commit = '1c1ccfe285676856ae719d27e9e90aaff23d42db'

repo_location = "/tmp/#{SecureRandom.hex}"

puts "cloning repo to #{repo_location}"

repo = Rugged::Repository.clone_at(
  head_repo_clone_url,
  repo_location)

repo.remotes.create('upstream', base_repo_clone_url)
repo.fetch('upstream')

new_tip = merge_base = repo.merge_base(tip_commit, base_commit)

puts "selected #{merge_base} as merge base"

Rugged::Walker.walk(
  repo,
  :sort => Rugged::SORT_TOPO | Rugged::SORT_REVERSE, # parents first
  :show => tip_commit,
  :hide => merge_base) {
  |commit|
    puts "anonymizing #{commit.oid}"
    current = Rugged::Commit.create(
      repo,
      :message => commit.message,
      :committer => commit.committer,
      :tree => commit.tree,
      #TODO: inside a PR, can a commit have more than one parent?
      :parents => [new_tip],
      :author => {
        :name => 'Scooby Doo',
        :email => 'scooby@anonydog.org',
        :time => commit.author[:time]
      }
    )

    new_tip = current
}

puts 'Your anonymized commit is ' + new_tip

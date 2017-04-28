# we need to set this here because rugged and libgit2 return ascii strings
# encoding: US-ASCII

require 'minitest/autorun'
require 'anonydog/local' # FIXME A05E92A2: i'd like to just 'require anonydog'

class AnonymizeTest < MiniTest::Test
  # repo layout for reference
  #
  #   maintainer/
  #     master    contributor
  #       |          /
  #       |         o bf6a
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

  HEAD_REPO_CLONE_URL = 'https://github.com/anonydog/testing-contributor_repo.git'
  BASE_REPO_CLONE_URL = 'https://github.com/anonydog/testing-maintainer_repo.git'

  def test_non_ff
    # non ff PR (needs to identify merge base)
    # contributor repo is not up-to-date (needs to fetch upstream)

    upstream_ref = 'master'
    pr_head = '1c1ccfe285676856ae719d27e9e90aaff23d42db'

    anonymized_repo = Anonydog::Local.anonymize(
      :head => {
        :clone_url => HEAD_REPO_CLONE_URL,
        :commit => pr_head
      },
      :base => {
        :clone_url => BASE_REPO_CLONE_URL,
        :ref => upstream_ref
      },
      :anonymized_branch => 'pullrequest-12345'
    )

    anonymized_ref = anonymized_repo.head

    assert(anonymized_ref.branch?)
    assert_equal('refs/heads/pullrequest-12345', anonymized_ref.name)

    anonymized_commit = anonymized_ref.target

    assert_equal("d4133014d4b8ed5e18f093f8aa404dc40d6caa19", anonymized_commit.oid)
    # traverse (three) commits starting from most recent
    (1..3).each do |i|
      assert_equal("Anonydog", anonymized_commit.author[:name], "commit author #{i}")
      assert_equal("me@anonydog.org", anonymized_commit.author[:email], "commit author #{i}")
      assert_equal(anonymized_commit.author[:name], anonymized_commit.committer[:name], "commit committer #{i}")
      assert_equal(anonymized_commit.author[:email], anonymized_commit.committer[:email], "commit committer #{i}")

      anonymized_commit = anonymized_commit.parents[0]
    end

    # we're no longer in anonymized area
    upstream_commit = anonymized_commit

    assert_equal("487958f50bc90109f3b1ed89701894b1fe5a03ee", upstream_commit.oid, "unexpected merge base")
    assert_equal("Thiago Arrais", upstream_commit.author[:name])
    assert_equal("thiago.arrais@gmail.com", upstream_commit.author[:email])
  end

  def test_commits_added
    # let's say the contributor added some commits to the PR...
    upstream_ref = 'master'
    pr_head = 'bf6abb8eacd0f6eb5b373b221ac46fc36d341079'

    anonymized_repo = Anonydog::Local.anonymize(
      :head => {
        :clone_url => HEAD_REPO_CLONE_URL,
        :commit => pr_head
      },
      :base => {
        :clone_url => BASE_REPO_CLONE_URL,
        :ref => upstream_ref
      },
      :anonymized_branch => 'pullrequest-12345'
    )

    anonymized_commit = anonymized_repo.head.target

    # we're not interested in the tip/head commit. we believe it is correctly
    # anonymized. we're interested in its parent instead.
    parent_commit = anonymized_commit.parents[0]

    # but did its parent get anonymized to the same sha-256 as when it was the
    # branch tip? or will it look to the PR reviewer as a rewriting of history?
    assert_equal("d4133014d4b8ed5e18f093f8aa404dc40d6caa19", parent_commit.oid)
  end
end
# we need to set this here because rugged/libgit2 return ascii strings
# encoding: US-ASCII

require 'minitest/autorun'
require 'anonydog'
require 'rugged'

class AnonymizeTest < MiniTest::Test
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

  HEAD_REPO_CLONE_URL = 'https://github.com/anonydog/testing-contributor_repo.git'
  BASE_REPO_CLONE_URL = 'https://github.com/anonydog/testing-maintainer_repo.git'

  def test_non_ff
    # non ff PR (needs to identify merge base)
    # contributor repo is not up-to-date (needs to fetch upstream)

    upstream_head = 'c118828dd9d5669da9755a03b03f1a240a71864d'
    pr_head = '1c1ccfe285676856ae719d27e9e90aaff23d42db'

    anonymized_pr = Anonydog::Local.anonymize(
      :head => {
        :clone_url => HEAD_REPO_CLONE_URL,
        :commit => pr_head
      },
      :base => {
        :clone_url => BASE_REPO_CLONE_URL,
        :commit => upstream_head
      }
    )

    anonymized_repo = Rugged::Repository.new(anonymized_pr.repo_path)
    anonymized_commit = anonymized_repo.lookup(anonymized_pr.head)

    assert_equal("d0098fb205f9c32422e318bd3ebfb1520acad32c", anonymized_commit.oid)
    # check if all three commits were anonymized
    (1..3).each do |i|
      assert_equal("Scooby Doo", anonymized_commit.author[:name], "commit #{i}")
      assert_equal("scooby@anonydog.org", anonymized_commit.author[:email], "commit #{i}")

      anonymized_commit = anonymized_commit.parents[0]
    end

    # we're no longer in anonymized area
    upstream_commit = anonymized_commit

    assert_equal("487958f50bc90109f3b1ed89701894b1fe5a03ee", upstream_commit.oid, "unexpected merge base")
    assert_equal("Thiago Arrais", upstream_commit.author[:name])
    assert_equal("thiago.arrais@gmail.com", upstream_commit.author[:email])
  end
end

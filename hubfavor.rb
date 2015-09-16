#!/usr/bin/env ruby
require "optparse"
require "octokit"
require "colorize"
require "thread/pool"
require "dotenv"
Dotenv.load

DEFAULT_MAX_THREADS = 20

# quick helper method to check for github user from gitconfig, since it is
# often defined there instead of in an environment variable
def github_user_from_gitconfig
  results = `git config github.user`.chomp
  return nil if results.empty?
  results
end

# actual user defaults are determined by environment
$options = {
  access_token: ENV["GITHUB_ACCESS_TOKEN"]  || ENV["OCTOKIT_ACCESS_TOKEN"],
  username:     ENV["GITHUB_USER"]          || github_user_from_gitconfig || ENV["USER"],
  threads:      ENV["HUBFAVOR_MAX_THREADS"] || DEFAULT_MAX_THREADS,
  verbose:      false,
  target:       nil,
}

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{opts.program_name} [options] <organization>"
  opts.on("-u", "--user=#{$options[:username]}", String,
          "GitHub username of yourself") do |t|
    $options[:username] = t
  end
  opts.on("-c", "--threads=#{$options[:threads]}", Integer,
          "Number of simultaneous queries") do |t|
    $options[:threads] = t
  end
  opts.on("-v", "--verbose", "Output scanned users regardless of match") do
    $options[:verbose] = true
  end
  opts.on_tail("-h", "--help", "Display this help screen") do
    puts opts; exit
  end
end
opt_parser.parse!

$options[:target] = ARGV.pop
unless $options[:target]
  puts opt_parser; exit 1
end

if $options[:access_token]
  Octokit.configure { |c| c.access_token = $options[:access_token] }
else
  warn(
    "No acccess token found! Set the $GITHUB_ACCESS_TOKEN environment variable.",
    "Without one it is *extremely* likely you will run out of API queries.\n\n"
  )
end
puts "Need a favor from someone at #{$options[:target]}, huh?"

# basically we just abuse the shit out of auto_paginate to make life simple
Octokit.auto_paginate = true

def get_followers(username)
  print "Retrieving followers for #{username}... "
  followers = Octokit.followers(username).map(&:login)
  puts "found #{followers.length}."
  followers
end

def get_org_members(orgname)
  print "Retrieving organization members of #{orgname}... "
  members = Octokit.organization_members(orgname).map(&:login)
  puts "found #{members.length}."
  members
end

MINIONS = get_followers($options[:username])
CANDIDATE_USERS = get_org_members($options[:target])

class Candidate
  attr_accessor :username

  def initialize(username)
    @username = username
  end

  def follows_me?
    MINIONS.include? @username
  end

  def starred
    @starred ||= Octokit.starred(@username)
  end

  def my_repos_starred
    @my_repos_starred ||= starred.select { |r| r.owner.login == $options[:username] }
  end

  def match?
    follows_me? || my_repos_starred.count >= 1
  end

  def score
    my_repos_starred.count + (follows_me? ? 1 : 0)
  end

  def evaluate_verbosely
    msg = "-> "
    if match?
      msg << "#{@username}".ljust(20).white.bold
      msg << "[👀 follower]" if follows_me?
      my_repos_starred.each do |repo|
        msg << "[🌟 #{repo.name}]"
      end
      puts msg
    else
      puts msg + @username if $options[:verbose]
    end
  end

end

puts "Stargazing... (#{$options[:threads]} simultaneous queries)"
start_time = Time.now
candidates = CANDIDATE_USERS.map { |user| Candidate.new(user) }
pool = Thread.pool($options[:threads])
candidates.each do |candidate|
  pool.process { candidate.evaluate_verbosely }
end
pool.shutdown

ranked = candidates.select { |c| c.score > 0 }.sort_by(&:score).reverse
puts "\n"
puts "Found #{ranked.count} candidates in #{(Time.now - start_time).round(2)} seconds."
puts "Most likely candidate: #{ranked.first.username}"

# frozen_string_literal: true
#
# Redmine Hearts plugin
# Copyright (C) @cat_in_136
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software

require 'active_record'

namespace :redmine_hearts do
  desc 'Delete all the hearts'
  task :delete_all_hearts => :environment do
    Heart.delete_all
    puts "Done."
  end

  desc "Migrate from issue_votes plugin to hearts"
  task :migrate_from_issue_votes => :environment do
    abort "issue_votes does not installed" unless Redmine::Plugin.installed?(:issue_votes)

    num_of_heart_before_processing = Heart.count

    IssueVote.all.each do |vote|
      issue = vote.issue
      user = vote.user
      datetime = vote.created_on || Time.now
      if issue.hearted_by?(user)
        # do nothing if already hearted
      else
        Heart.create!(
          :heartable => issue,
          :user => user,
          :created_at => datetime,
          :updated_at => datetime,
        )
      end
    end

    num_of_heart_added = Heart.count - num_of_heart_before_processing

    puts "#{num_of_heart_added} #{(num_of_heart_added > 1)? 'heart'.pluralize : 'heart'} added."
  end

  desc "Migrate to issue_votes plugin from hearts"
  task :migrate_to_issue_votes => :environment do
    abort "issue_votes does not installed" unless Redmine::Plugin.installed?(:issue_votes)

    num_of_vote_before_processing = IssueVote.count

    Heart.where(:heartable_type => Issue).each do |heart|
      issue = heart.heartable
      user = heart.user
      project = issue.project
      created_on = heart.created_at

      if IssueVote.where(:issue => issue, :user => user).exists?
        # do nothing if already voted
      else
        IssueVote.create!(
          :issue => issue,
          :user => user,
          :vote_value => 1,
          :project => project,
          :created_on => created_on,
        )
      end
    end

    num_of_vote_added = IssueVote.count - num_of_vote_before_processing

    puts "#{num_of_vote_added} #{(num_of_vote_added > 1)? 'vote'.pluralize : 'vote'} added."
  end

  desc "Migrate from vote_on_issues plugin to hearts"
  task :migrate_from_vote_on_issues => :environment do
    abort "vote_on_issues does not installed" unless Redmine::Plugin.installed?(:vote_on_issues)

    num_of_heart_before_processing = Heart.count

    VoteOnIssue.where('vote_val > 0').where.not(issue: nil, user: nil).each do |vote|
      issue = vote.issue
      user = vote.user
      datetime = vote.created_at || Time.now
      if issue.hearted_by?(user)
        # do nothing if already hearted
      else
        Heart.create!(
          :heartable => issue,
          :user => user,
          :created_at => datetime,
          :updated_at => datetime,
          :skip_validate_user => true,
        )
      end
    end

    num_of_heart_added = Heart.count - num_of_heart_before_processing

    puts "#{num_of_heart_added} #{(num_of_heart_added > 1)? 'heart'.pluralize : 'heart'} added."
  end

  desc "Migrate to vote_on_issues plugin from hearts"
  task :migrate_to_vote_on_issues => :environment do
    abort "vote_on_issues does not installed" unless Redmine::Plugin.installed?(:vote_on_issues)

    num_of_vote_on_issues_before_processing = VoteOnIssue.count

    Heart.where(:heartable_type => Issue).each do |heart|
      user = heart.user
      issue = heart.heartable
      created_at = heart.created_at

      if VoteOnIssue.where(:issue => issue, :user => user).exists?
        # do nothing if already voted
      else
        VoteOnIssue.create!(
          :user => user,
          :issue => issue,
          :vote_val => 1,
          :created_at => created_at,
          :updated_at => created_at,
        )
      end
    end

    num_of_vote_on_issue_added = VoteOnIssue.count - num_of_vote_on_issues_before_processing

    puts "#{num_of_vote_on_issue_added} #{(num_of_vote_on_issue_added > 1)? 'vote'.pluralize : 'vote'} added."
  end

end

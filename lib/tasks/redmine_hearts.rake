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

end

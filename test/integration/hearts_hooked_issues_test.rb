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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class HeartsHookedIssuesTest < Redmine::IntegrationTest
  include Redmine::PluginFixtureSetLoader

  fixtures :projects,
           :users,
           :members,
           :member_roles,
           :roles,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :issue_statuses,
           :issues,
           :journals,
           :enumerations,
           :custom_fields,
           :custom_values,
           :custom_fields_trackers
  plugin_fixtures :hearts

  def test_index_shall_not_contain_hooks
    get '/projects/1/issues/'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 0
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 0
    assert_select '.heart-link-with-count', :count => 0
  end

  def test_index_with_heart_column
    get '/issues?set_filter=1&sort=hearts.count:desc,id&c[]=subject&c[]=hearts.count'
    assert_response :success
    assert_select 'thead > tr > th:nth-child(4)', :text => 'Like'
    assert_select 'td.id', :text => '5'
    assert_select 'tbody > tr#issue-2:first-child td.hearts-count', :text => '2'
  end

  def test_view
    get '/issues/1'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 1
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 1

    assert_select '#content > .heart-link-with-count.issue-1-heart', :count => 1
    assert_select '#content > .heart-link-with-count.issue-1-heart span.heart-count-number', :text => "0"
    assert_select '.journal-heart-holder > .heart-link-with-count.journal-1-heart', :count => 1
    assert_select '.journal-heart-holder > .heart-link-with-count.journal-1-heart span.heart-count-number', :text => "1"
    assert_select '.journal-heart-holder > .heart-link-with-count.journal-2-heart', :count => 1
    assert_select '.journal-heart-holder > .heart-link-with-count.journal-2-heart span.heart-count-number', :text => "0"
    assert_select '.heart-link-with-count', :count => 3
  end

  def test_view_by_hearted_user
    log_user('dlopper', 'foo')
    get '/issues/2'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 1
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 1

    assert_select '#content > .heart-link-with-count.issue-2-heart', :count => 1
    assert_select '#content > .heart-link-with-count.issue-2-heart a.heart-count-number', :text => "2"
    assert_select '.journal-heart-holder > .heart-link-with-count.journal-3-heart', :count => 1
    assert_select '.journal-heart-holder > .heart-link-with-count.journal-3-heart a.heart-count-number', :text => "0"
    assert_select '.heart-link-with-count', :count => 2
  end

  def test_view_with_private_notes
    Journal.where(:journalized => Issue.find(1)).delete_all
    30.times do |idx|
      journal = Journal.new(:user_id => 3, :journalized => Issue.find(1), :notes => "foobarbaz", :private_notes => (idx % 10 == 1))
      journal.notify = false # to suppress email notification
      journal.save
    end

    get '/issues/1'
    assert_response :success

    assert_select '#content > .heart-link-with-count.issue-1-heart', :count => 1
    assert_select '.journal-heart-holder > .heart-link-with-count', :count => (30 - 3)
    assert_select '.heart-link-with-count', :count => 1 + (30 - 3)
  end
end

# frozen_string_literal: true
#
# Redmine Hearts plugin
# Copyright (C) @cat_in_136
# Copyright (C) 2006-2017  Jean-Philippe Lang (Almost-all method code are copied from redmine)
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

require File.expand_path('../../../test_helper', __FILE__)

class HeartsHelperTest < Redmine::HelperTest
  include HeartsHelper
  include ERB::Util

  include Rails.application.routes.url_helpers

  fixtures :users, :projects,
    :boards, :issues, :messages, :news, :wikis, :wiki_pages, :journals

  test '#heart_link_with_counter with a non-hearted object' do
    expected = content_tag(:span, :class => "issue-1-heart heart-link-with-count") do
      safe_join(
        [
          link_to(
            content_tag(:span, "Like", :class => 'heart-link-label'),
            heart_url(:object_id => 1, :object_type => 'issue'),
            :remote => true, :method => 'post', :class => "icon icon-heart-off"
          ),
          link_to(
            "0",
            hearts_hearted_users_url(:object_id => 1, :object_type => 'issue'),
            :class => "heart-count-number"
          ),
        ],
        ""
      )
    end
    assert_equal expected, heart_link_with_counter(Issue.find(1), User.find(1))
    assert_equal expected, heart_link_with_counter([Issue.find(1)], User.find(1))
  end

  test '#heart_link_with_counter with a non-hearted object for anonymous user' do
    expected = content_tag(:span, :class => "issue-1-heart heart-link-with-count") do
      safe_join(
        [
          content_tag(:span,
                      content_tag(:span, "Like", :class => 'heart-link-label'),
                      :class => "icon icon-heart-off"),
          content_tag(:span, "0", :class => "heart-count-number"),
        ],
        ""
      )
    end
    assert_equal expected, heart_link_with_counter(Issue.find(1), User.anonymous)
  end

  test '#heart_link_with_counter with a multiple objets array' do
    expected = content_tag(:span, :class => "issue-bulk-heart heart-link-with-count") do
      safe_join(
        [
          link_to(
            content_tag(:span, "Like", :class => 'heart-link-label'),
            heart_url(:object_id => [1, 3], :object_type => 'issue'),
            :remote => true, :method => 'post', :class => "icon icon-heart-off"
          ),
          link_to(
            "0",
            hearts_hearted_users_url(:object_id => [1, 3], :object_type => 'issue'),
            :class => "heart-count-number"
          ),
        ],
        ""
      )
    end
    assert_equal expected, heart_link_with_counter([Issue.find(1), Issue.find(3)], User.find(1))
  end

  def test_heart_link_with_counter_with_nil_should_return_empty_string
    assert_equal '', heart_link_with_counter(nil, User.find(1))
  end

  test '#heart_link_with_counter with a hearted object' do
    Heart.create!(:heartable => Issue.find(1), :user => User.find(1))

    expected = content_tag(:span, :class => "issue-1-heart heart-link-with-count") do
      safe_join(
        [
          link_to(
            content_tag(:span, "Like", :class => 'heart-link-label'),
            heart_url(:object_id => 1, :object_type => 'issue'),
            :remote => true, :method => 'delete', :class => "icon icon-heart"
          ),
          link_to(
            "1",
            hearts_hearted_users_url(:object_id => 1, :object_type => 'issue'),
            :class => "heart-count-number"
          ),
        ],
        ""
      )
    end
    assert_equal expected, heart_link_with_counter(Issue.find(1), User.find(1))
  end

  test '#heart_link_with_counter with a hearted object for anonymous user' do
    Heart.create!(:heartable => Issue.find(1), :user => User.find(1))

    expected = content_tag(:span, :class => "issue-1-heart heart-link-with-count") do
      safe_join(
        [
          content_tag(:span,
                      content_tag(:span, "Like", :class => 'heart-link-label'),
                      :class => "icon icon-heart-off"),
          content_tag(:span, "1", :class => "heart-count-number"),
        ],
        ""
      )
    end
    assert_equal expected, heart_link_with_counter(Issue.find(1), User.anonymous)
  end

  test '#multiple_heart_links_with_counters with multiple objects' do
    queries = []
    active_record_callback = lambda do |name, start, finish, id, payload|
      queries << payload if payload[:sql] =~ /^SELECT|UPDATA|INSERT/
    end

    Heart.create!(:heartable => Issue.find(1), :user => User.find(1))

    expected = [
      heart_link_with_counter(Issue.find(1), User.find(1)),
      heart_link_with_counter(Issue.find(2), User.find(1)),
    ]

    ActiveSupport::Notifications.subscribed(active_record_callback, "sql.active_record") do
      assert_equal expected, multiple_heart_links_with_counters([Issue.find(1), Issue.find(2)], User.find(1))
    end

    # assert 5 query calls
    #  - Issue.find(1), Issue.find(2), User.find(1), and 2 calls within multiple_heart_links_with_counters.
    assert_equal 5, queries.length
  end

  test '#multiple_heart_links_with_counters with multiple objects for anonymous user' do
    queries = []
    active_record_callback = lambda do |name, start, finish, id, payload|
      queries << payload if payload[:sql] =~ /^SELECT|UPDATA|INSERT/
    end

    Heart.create!(:heartable => Issue.find(1), :user => User.find(1))

    expected = [
      heart_link_with_counter(Issue.find(1), User.anonymous),
      heart_link_with_counter(Issue.find(2), User.anonymous),
    ]

    ActiveSupport::Notifications.subscribed(active_record_callback, "sql.active_record") do
      assert_equal expected, multiple_heart_links_with_counters([Issue.find(1), Issue.find(2)], User.anonymous)
    end

    # assert 5 query calls
    #  - Issue.find(1), Issue.find(2), User.anonymous, and 2 calls within multiple_heart_links_with_counters.
    assert_equal 5, queries.length
  end

  test '#multiple_heart_links_with_counters with nil and empty array should return empty array' do
    assert_equal [], multiple_heart_links_with_counters(nil, User.find(1))
    assert_equal [], multiple_heart_links_with_counters([], User.find(1))
  end


  {
    :board => "link_to 'Help', project_board_url(object.project, object, :only_path => true)",
    :issue => "link_to_issue(object, :only_path => true)",
    :message => "link_to_message(object, :only_path => true)",
    :news => "link_to 'eCookbook first release !', news_url(object, :only_path => true)",
    :wiki => "link_to 'Wiki', project_wiki_url(object.project, :only_path => true)",
    :wiki_page => "link_to 'CookBook_documentation', object",
    :journal => "link_to_issue(object.issue, :only_path => true) + ': ' + link_to('#1#note-1', issue_url(object.issue, :anchor => 'note-1', :only_path => true))",

    :user => "link_to 'Redmine Admin', '/users/1'", # fallback to link_to object
    :project => "link_to 'eCookbook', '/projects/ecookbook'", # fallback to link_to object
  }.each do |k,v|
    test "#link_to_heartable_with_#{k}" do
      object = k.to_s.classify.constantize.find(1)
      expected = eval(v)
      assert_equal expected, link_to_heartable(object)
    end
  end
  test "#link_to_heartable_with_nil" do
    assert_raises { link_to_heartable(nil) }
  end
end

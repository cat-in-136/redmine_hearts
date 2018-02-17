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
  include Rails.application.routes.url_helpers

  fixtures :users, :issues

  test '#heart_link_with_counter with a non-hearted object' do
    expected = content_tag(:span, :class => "issue-1-heart heart-link-with-count") do
      safe_join(
        [
          link_to(
            "Like",
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

  test '#heart_link_with_counter with a multiple objets array' do
    expected = content_tag(:span, :class => "issue-bulk-heart heart-link-with-count") do
      safe_join(
        [
          link_to(
            "Like",
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
            "Like",
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
end

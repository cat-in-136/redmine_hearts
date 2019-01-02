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

class HeartsHookedBoardsTest < Redmine::IntegrationTest
  include Redmine::PluginFixtureSetLoader

  fixtures :projects, :enabled_modules,
           :users,
           :boards, :messages
  plugin_fixtures :hearts

  def test_index_shall_not_contain_hooks
    get '/projects/1/boards/'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 0
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 0
    assert_select '.heart-link-with-count', :count => 0
  end

  def test_topic_view
    get '/boards/1/topics/1'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 1
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 1

    assert_select '#content > .heart-link-with-count.message-1-heart', :count => 1
    assert_select '#content > .heart-link-with-count.message-1-heart .heart-count-number', :text => "1"
    assert_select '.replies-heart-holder > .heart-link-with-count.message-2-heart', :count => 1
    assert_select '.replies-heart-holder > .heart-link-with-count.message-2-heart .heart-count-number', :text => "0"
    assert_select '.replies-heart-holder > .heart-link-with-count.message-3-heart', :count => 1
    assert_select '.replies-heart-holder > .heart-link-with-count.message-3-heart .heart-count-number', :text => "0"
    assert_select '.heart-link-with-count', :count => 3
  end

  def test_topic_view_with_paginate
    message = Message.find(1)
    30.times do
      message.children << Message.new(:subject => 'foo', :content => 'bar', :author_id => 2, :board_id => 1)
    end

    get '/boards/1/topics/1'
    assert_response :success

    assert_select '.heart-link-with-count', :count => (1 + MessagesController::REPLIES_PER_PAGE)
  end
end

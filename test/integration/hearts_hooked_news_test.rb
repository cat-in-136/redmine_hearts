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

class HeartsHookedNewsTest < Redmine::IntegrationTest
  include Redmine::PluginFixtureSetLoader

  fixtures :projects, :enabled_modules,
           :users,
           :roles, :member_roles, :members,
           :news
  plugin_fixtures :hearts

  def test_index
    get '/news/'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 1
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 1

    assert_select '.heart-link-with-count', :count => 2
    assert_select '#content .news-heart-holder .heart-link-with-count.news-2-heart', :count => 1
    assert_select '#content .news-heart-holder .heart-link-with-count.news-2-heart span.heart-count-number', :text => "0"
    assert_select '#content .news-heart-holder .heart-link-with-count.news-1-heart', :count => 1
    assert_select '#content .news-heart-holder .heart-link-with-count.news-1-heart span.heart-count-number', :text => "1"
  end

  def test_view
    Heart.where(:heartable => News.find(1)).destroy_all

    get '/news/1'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 1
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 1

    assert_select '#content > .heart-link-with-count.news-1-heart', :count => 1
    assert_select '#content > .heart-link-with-count.news-1-heart span.heart-count-number', :text => "0"
  end

  def test_view_by_hearted_user
    log_user('dlopper', 'foo')
    #Heart.create!(:heartable => News.find(1), :user_id => 3)

    get '/news/1'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 1
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 1

    assert_select '#content > .heart-link-with-count.news-1-heart', :count => 1
    assert_select '#content > .heart-link-with-count.news-1-heart a.heart-count-number', :text => "1"
  end
end

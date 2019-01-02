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

class HeartsHookedUsersTest < Redmine::IntegrationTest
  include Redmine::PluginFixtureSetLoader

  fixtures :projects,
           :users
  plugin_fixtures :hearts

  def test_show
    log_user('dlopper', 'foo')
    get '/users/1'
    assert_response :success
    assert_select 'script[src*="transplant_heart_link_with_counter.js"]', :count => 0
    assert_select 'link[href*="redmine_hearts/stylesheets/application.css"]', :count => 0
    assert_select 'a[href="/hearts/hearted_by/1"]', :count => 1, :text => "2 Likes"

    Heart.where(:user_id => 1).destroy_all
    get '/users/1'
    assert_response :success
    assert_select 'a[href="/hearts/hearted_by/1"]', :count => 0
  end
end

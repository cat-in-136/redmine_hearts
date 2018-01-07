# frozen_string_literal: true
#
# Redmine Hearts plugin
# Copyright (C) @cat_in_136
# Copyright (C) 2006-2017  Jean-Philippe Lang (Almost-all method code except for hearted_users are copied from redmine)
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

class HeartsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules,
           :issues, :trackers, :projects_trackers, :issue_statuses, :enumerations, :hearts

  def setup
    User.current = nil
  end

  def test_heart_a_single_object_as_html
    @request.session[:user_id] = 3
    assert_difference('Heart.count') do
      post :heart, :object_type => 'issue', :object_id => '1'
      assert_response :success
      assert_include 'Heart added', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_single_object
    @request.session[:user_id] = 3
    assert_difference('Heart.count') do
      post :heart, :object_type => 'issue', :object_id => '1', :format => :js
      assert_response :success
      assert_include '$(".issue-1-heart")', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_collection_with_a_single_object
    @request.session[:user_id] = 3
    assert_difference('Heart.count') do
      post :heart, :object_type => 'issue', :object_id => ['1'], :format => :js
      assert_response :success
      assert_include '$(".issue-1-heart")', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_collection_with_multipe_objects
    @request.session[:user_id] = 3
    assert_difference('Heart.count', 2) do
      post :heart, :object_type => 'issue', :object_id => ['1', '3'], :format => :js
      assert_response :success
      assert_include '$(".issue-bulk-heart")', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
    assert Issue.find(3).hearted_by?(User.find(3))
  end

  def test_unheart_a_single_object_as_html
    @request.session[:user_id] = 3
    assert_difference('Heart.count', -1) do
      delete :unheart, :object_type => 'issue', :object_id => '2'
      assert_response :success
      assert_include 'Heart removed', response.body
    end
    refute Issue.find(2).hearted_by?(User.find(3))
  end

  def test_unheart_a_single_object
    @request.session[:user_id] = 3
    assert_difference('Heart.count', -1) do
      delete :unheart, :object_type => 'issue', :object_id => '2', :format => :js
      assert_response :success
      assert_include '$(".issue-2-heart")', response.body
    end
    refute Issue.find(2).hearted_by?(User.find(3))
  end

  def test_hearted_users_non_liked_object
    @request.session[:user_id] = 3
    get :hearted_users, :object_type => 'issue', :object_id => '1'
    assert_response :success
    assert_select '#content h3', {:text => "Not liked yet"}
    assert_select '#content ul', {:count => 0}
  end

  def test_hearted_users_liked_object
    @request.session[:user_id] = 3
    get :hearted_users, :object_type => 'issue', :object_id => '2'
    assert_response :success
    assert_select '#content h3', {:text => "2 Likes"}
    assert_select '#content ul li', {:count => 2}
  end

end

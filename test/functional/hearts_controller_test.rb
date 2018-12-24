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
  include Redmine::PluginFixtureSetLoader

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules,
           :issues, :issue_statuses, :enumerations, :trackers, :projects_trackers,
           :boards, :messages,
           :wikis, :wiki_pages,
           :news, :comments,
           :journals, :journal_details
  plugin_fixtures :hearts

  def setup
    User.current = nil
  end

  def params(params={})
    if Rails.version >= "5"
      {:params => params}
    else
      params
    end
  end
  private :params

  def test_index
    @request.session[:user_id] = 3
    get :index
    assert_response :success
    assert_select '#content > ul.recent-heart-list > li', {:count => 2}
    assert_select '#content > ul.recent-heart-list > li:nth-child(1) a[href="/boards/1/topics/1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(1) a[href="/users/1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(2) a[href="/issues/2"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(2) a[href="/users/1"]', {:count => 1}
  end

  def test_index_including_myself
    @request.session[:user_id] = 3
    get :index, params(:including_myself => true)
    assert_response :success
    assert_select '#content > ul.recent-heart-list > li', {:count => 7}
    assert_select '#content > ul.recent-heart-list > li:nth-child(1) a[href="/projects/ecookbook/boards/1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(1) a[href="/users/3"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(2) a[href="/issues/1#note-1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(2) a[href="/users/3"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(3) a[href="/news/1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(3) a[href="/users/3"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(4) a[href="/projects/ecookbook/wiki/CookBook_documentation"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(4) a[href="/users/3"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(5) a[href="/projects/ecookbook/wiki"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(5) a[href="/users/3"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(6) a[href="/boards/1/topics/1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(6) a[href="/users/1"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(7) a[href="/issues/2"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(7) a[href="/users/3"]', {:count => 1}
    assert_select '#content > ul.recent-heart-list > li:nth-child(7) a[href="/users/1"]', {:count => 1}
  end

  def test_index_as_api
    with_settings :rest_api_enabled => '1' do
      get :index, params(
        :format => 'json',
        :key => User.find(3).api_key,
      )
    end
    assert_response :success
    assert_equal 'application/json', @response.content_type

    response_as_json = JSON.parse(@response.body)
    expected = {"heartables" => [
      {"object_type" => "message",
       "object_id" => 1,
       "subject" => "First post",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 1, "name" => "Redmine Admin"},
                     "created_at" => "2007-05-13T16:16:33Z"}]},
      {"object_type" => "issue",
       "object_id" => 2,
       "subject" => "Add ingredients categories",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 2,
       "hearts" => [{"user" => {"id" => 1, "name" => "Redmine Admin"},
                     "created_at" => "2006-07-20T20:10:51Z"}]},
    ],
                "total_count" => 2,
                "offset" => 0,
                "limit" => 25,
                "including_myself" => false}
    assert_equal expected, response_as_json
  end

  def test_index_including_myself_as_api
    with_settings :rest_api_enabled => '1' do
      get :index, params(
        :format => 'json',
        :key => User.find(3).api_key,
        :including_myself => true,
      )
    end
    assert_response :success
    assert_equal 'application/json', @response.content_type

    response_as_json = JSON.parse(@response.body)
    expected = {"heartables" => [
      {"object_type" => "board",
       "object_id" => 1,
       "name" => "Help",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2010-10-01T10:34:04Z"}]},
      {"object_type" => "journal",
       "object_id" => 1,
       "project" => {"id" => 1, "name" => "eCookbook"},
       "journalized" => {"type" => "Issue", "id" => 1, "note_index" => 1},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2010-05-05T10:34:08Z"}]},
      {"object_type" => "news",
       "object_id" => 1,
       "title" => "eCookbook first release !",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2010-05-04T10:34:07Z"}]},
      {"object_type" => "wikipage",
       "object_id" => 1,
       "title" => "CookBook_documentation",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2010-05-03T10:34:06Z"}]},
      {"object_type" => "wiki",
       "object_id" => 1,
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2010-01-02T10:34:05Z"}]},
      {"object_type" => "message",
       "object_id" => 1,
       "subject" => "First post",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 1, "name" => "Redmine Admin"},
                     "created_at" => "2007-05-13T16:16:33Z"}]},
      {"object_type" => "issue",
       "object_id" => 2,
       "subject" => "Add ingredients categories",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 2,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2006-07-21T20:10:51Z"},
                    {"user" => {"id" => 1, "name" => "Redmine Admin"},
                     "created_at" => "2006-07-20T20:10:51Z"}]},
    ],
                "total_count" => 7,
                "offset" => 0,
                "limit" => 25,
                "including_myself" => true}
    assert_equal expected, response_as_json
  end

  def test_index_with_offset_limit_as_api
    with_settings :rest_api_enabled => '1' do
      get :index, params(
        :format => 'json',
        :offset => 3,
        :limit => 1,
        :including_myself => true,
        :key => User.find(3).api_key,
      )
    end
    assert_response :success
    assert_equal "application/json", @response.content_type

    response_as_json = JSON.parse(@response.body)
    expected = {"heartables" => [
      {"object_type" => "wikipage",
       "object_id" => 1,
       "title" => "CookBook_documentation",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 1,
       "hearts" => [{"user" => {"id" => 3, "name" => "Dave Lopper"},
                     "created_at" => "2010-05-03T10:34:06Z"}]},
    ],
                "total_count" => 7,
                "offset" => 3,
                "limit" => 1,
                "including_myself" => true}
    assert_equal expected, response_as_json
  end

  def test_index_with_project
    @request.session[:user_id] = 3
    Issue.find(5).set_heart(User.find(1), true)

    get :index, params(:project_id => 1)
    assert_response :success
    assert_select '#content > ul > li', {:count => 2}
    assert_select '#content > ul > li:nth-child(1) a[href="/boards/1/topics/1"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(2) a[href="/issues/2"]', {:count => 1}

    get :index, params(:project_id => 3)
    assert_response :success
    assert_select '#content > ul > li', {:count => 1}
    assert_select '#content > ul > li:nth-child(1) a[href="/issues/5"]', {:count => 1}
  end

  def test_notifications
    @request.session[:user_id] = 2

    get :notifications
    assert_response :success
    assert_select '#content > ul > li', {:count => 2}
    assert_select '#content > ul > li:nth-child(1) a[href="/news/1"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(2) a[href="/issues/2"]', {:count => 1}
  end

  def test_hearted_by
    get :hearted_by, params(:user_id => 1)
    assert_response :success
    assert_select '#content > ul > li', {:count => 2}
    assert_select '#content > ul > li:nth-child(1) a[href="/boards/1/topics/1"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(2) a[href="/issues/2"]', {:count => 1}

    get :hearted_by, params(:user_id => 3)
    assert_response :success
    assert_select '#content > ul > li', {:count => 6}
    assert_select '#content > ul > li:nth-child(1) a[href="/projects/ecookbook/boards/1"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(2) a[href="/issues/1#note-1"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(3) a[href="/news/1"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(4) a[href="/projects/ecookbook/wiki/CookBook_documentation"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(5) a[href="/projects/ecookbook/wiki"]', {:count => 1}
    assert_select '#content > ul > li:nth-child(6) a[href="/issues/2"]', {:count => 1}
  end

  def test_hearted_by_as_api
    with_settings :rest_api_enabled => '1' do
      get :hearted_by, params(
        :user_id => '1',
        :format => 'json',
        :key => User.find(3).api_key,
      )
    end
    assert_response :success
    assert_equal 'application/json', @response.content_type

    response_as_json = JSON.parse(@response.body)
    expected = {"heartables" => [
      {
        "object_type" => "message",
        "object_id" => 1,
        "subject" => "First post",
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 1, "name" => "Redmine Admin"},
                    "created_at" => "2007-05-13T16:16:33Z"},
      },
      {
        "object_type" => "issue",
        "object_id" => 2,
        "subject" => "Add ingredients categories",
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 1, "name" => "Redmine Admin"},
                    "created_at" => "2006-07-20T20:10:51Z"},
      },
    ],
                "total_count" => 2,
                "offset" => 0,
                "limit" => 25}
    assert_equal expected, response_as_json

    with_settings :rest_api_enabled => '1' do
      get :hearted_by, params(
        :user_id => '3',
        :format => 'json',
        :key => User.find(3).api_key,
      )
    end
    assert_response :success
    assert_equal 'application/json', @response.content_type

    response_as_json = JSON.parse(@response.body)
    expected = {"heartables" => [
      {
        "object_type" => "board",
        "object_id" => 1,
        "name" => "Help",
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 3, "name" => "Dave Lopper"},
                    "created_at" => "2010-10-01T10:34:04Z"},
      },
      {
        "object_type" => "journal",
        "object_id" => 1,
        "project" => {"id" => 1, "name" => "eCookbook"},
        "journalized" => {"type" => "Issue", "id" => 1, "note_index" => 1},
        "heart" => {"user" => {"id" => 3, "name" => "Dave Lopper"},
                    "created_at" => "2010-05-05T10:34:08Z"},
      },
      {
        "object_type" => "news",
        "object_id" => 1,
        "title" => "eCookbook first release !",
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 3, "name" => "Dave Lopper"},
                    "created_at" => "2010-05-04T10:34:07Z"},
      },
      {
        "object_type" => "wikipage",
        "object_id" => 1,
        "title" => "CookBook_documentation",
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 3, "name" => "Dave Lopper"},
                    "created_at" => "2010-05-03T10:34:06Z"},
      },
      {
        "object_type" => "wiki",
        "object_id" => 1,
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 3, "name" => "Dave Lopper"},
                    "created_at" => "2010-01-02T10:34:05Z"},
      },
      {
        "object_type" => "issue",
        "object_id" => 2,
        "subject" => "Add ingredients categories",
        "project" => {"id" => 1, "name" => "eCookbook"},
        "heart" => {"user" => {"id" => 3, "name" => "Dave Lopper"},
                    "created_at" => "2006-07-21T20:10:51Z"},
      },
    ],
                "total_count" => 6,
                "offset" => 0,
                "limit" => 25}
    assert_equal expected, response_as_json
  end

  def test_heart_a_single_object_as_html
    @request.session[:user_id] = 3
    assert_difference('Heart.count') do
      post :heart, params(:object_type => 'issue', :object_id => '1')
      assert_response :success
      assert_include 'Heart added', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_single_object
    @request.session[:user_id] = 3
    assert_difference('Heart.count') do
      post :heart, params(:object_type => 'issue', :object_id => '1', :format => :js)
      assert_response :success
      assert_include '$(".issue-1-heart")', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_single_object_as_api
    assert_difference('Heart.count') do
      with_settings :rest_api_enabled => '1' do
        post :heart, params(
          :object_type => 'issue',
          :object_id => '1',
          :format => 'json',
          :key => User.find(3).api_key,
        )
      end
      assert_response :success
      assert_equal 'application/json', @response.content_type
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_collection_with_a_single_object
    @request.session[:user_id] = 3
    assert_difference("Heart.count") do
      post :heart, params(:object_type => "issue", :object_id => ["1"], :format => :js)
      assert_response :success
      assert_include '$(".issue-1-heart")', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
  end

  def test_heart_a_collection_with_multipe_objects
    @request.session[:user_id] = 3
    assert_difference('Heart.count', 2) do
      post :heart, params(:object_type => 'issue', :object_id => ['1', '3'], :format => :js)
      assert_response :success
      assert_include '$(".issue-bulk-heart")', response.body
    end
    assert Issue.find(1).hearted_by?(User.find(3))
    assert Issue.find(3).hearted_by?(User.find(3))
  end

  def test_unheart_a_single_object_as_html
    @request.session[:user_id] = 3
    assert_difference('Heart.count', -1) do
      delete :unheart, params(:object_type => 'issue', :object_id => '2')
      assert_response :success
      assert_include 'Heart removed', response.body
    end
    refute Issue.find(2).hearted_by?(User.find(3))
  end

  def test_unheart_a_single_object
    @request.session[:user_id] = 3
    assert_difference('Heart.count', -1) do
      delete :unheart, params(:object_type => 'issue', :object_id => '2', :format => :js)
      assert_response :success
      assert_include '$(".issue-2-heart")', response.body
    end
    refute Issue.find(2).hearted_by?(User.find(3))
  end

  def test_unheart_a_single_object_as_api
    assert_difference('Heart.count', -1) do
      with_settings :rest_api_enabled => '1' do
        post :unheart, params(
          :object_type => 'issue',
          :object_id => '2',
          :format => 'json',
          :key => User.find(3).api_key,
        )
      end
      assert_response :success
      assert_equal 'application/json', @response.content_type
    end
    refute Issue.find(2).hearted_by?(User.find(3))
  end

  def test_hearted_users_non_liked_object
    @request.session[:user_id] = 3
    get :hearted_users, params(:object_type => 'issue', :object_id => '1')
    assert_response :success
    assert_select '#content h3', {:text => "Not liked yet"}
    assert_select '#content ul', {:count => 0}
  end

  def test_hearted_users_non_liked_object_as_api
    with_settings :rest_api_enabled => '1' do
      get :hearted_users, params(
        :object_type => 'issue',
        :object_id => '2',
        :format => 'json',
        :key => User.find(3).api_key,
      )
    end
    assert_response :success
    assert_equal 'application/json', @response.content_type

    response_as_json = JSON.parse(@response.body)
    expected = {"heartables" => [
      {"object_type" => "issue",
       "object_id" => 2,
       "subject" => "Add ingredients categories",
       "project" => {"id" => 1, "name" => "eCookbook"},
       "hearted_users_count" => 2,
       "hearts" => [
        {"user" => {"id" => 3, "name" => "Dave Lopper"},
         "created_at" => "2006-07-21T20:10:51Z"},
        {"user" => {"id" => 1, "name" => "Redmine Admin"},
         "created_at" => "2006-07-20T20:10:51Z"},
      ]},
    ]}
    assert_equal expected, response_as_json
  end

  def test_hearted_users_liked_object
    @request.session[:user_id] = 3
    get :hearted_users, params(:object_type => 'issue', :object_id => '2')
    assert_response :success
    assert_select '#content h3', {:text => "2 Likes"}
    assert_select '#content ul li', {:count => 2}
  end
end

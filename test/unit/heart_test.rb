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

require File.expand_path('../../test_helper', __FILE__)

class HeartTest < ActiveSupport::TestCase
  include Redmine::PluginFixtureSetLoader

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules,
           :issues, :issue_statuses, :enumerations, :trackers, :projects_trackers,
           :boards, :messages,
           :wikis, :wiki_pages,
           :news, :comments,
           :journals, :journal_details
  plugin_fixtures :hearts

  def setup
    @user = User.find(1)
    @issue = Issue.find(1)
  end

  def test_validate
    user = User.find(5)
    assert !user.active?
    heart = Heart.new(:user_id => user.id)
    assert !heart.save
  end

  def test_heart
    assert @issue.add_heart(@user)
    @issue.reload
    assert @issue.hearts.detect { |w| w.user == @user }
  end

  def test_cant_heart_twice
    assert @issue.add_heart(@user)
    assert !@issue.add_heart(@user)
  end

  def test_hearted_by
    assert @issue.add_heart(@user)
    @issue.reload
    assert @issue.hearted_by?(@user)
    assert Issue.hearted_by(@user).include?(@issue)
  end

  def test_hearted_users
    hearted_users = Issue.find(2).hearted_users
    assert_kind_of Array, hearted_users.collect{|w| w}
    assert_kind_of User, hearted_users.first
  end

  def test_hearted_users_should_be_reloaded_after_adding_a_heart
    issue = Issue.find(2)
    user = User.generate!

    assert_difference 'issue.hearted_users.to_a.size' do
      issue.add_heart user
    end
  end

  def test_hearted_users_should_not_validate_user
    User.where(:id => 1).update_all("firstname = ''")
    @user.reload
    assert !@user.valid?

    issue = Issue.new(:project => Project.find(1), :tracker_id => 1, :subject => "test", :author => User.find(2))
    issue.hearted_users << @user
    issue.save!
    assert issue.hearted_by?(@user)
  end

  def test_hearted_user_ids
    assert_equal [1, 3], Issue.find(2).hearted_user_ids.sort
  end

  def test_hearted_user_ids=
    issue = Issue.new
    issue.hearted_user_ids = ['1', '3']
    assert issue.hearted_by?(User.find(1))
  end

  def test_hearted_user_ids_should_make_ids_uniq
    issue = Issue.new(:project => Project.find(1), :tracker_id => 1, :subject => "test", :author => User.find(2))
    issue.hearted_user_ids = ['1', '3', '1']
    issue.save!
    assert_equal 2, issue.hearts.count
  end

  def test_addable_hearted_users
    addable_hearted_users = @issue.addable_hearted_users
    assert_kind_of Array, addable_hearted_users
    assert_kind_of User, addable_hearted_users.first
  end

  def test_addable_hearted_users_should_not_include_user_that_cannot_view_the_object
    issue = Issue.new(:project => Project.find(1), :is_private => true)
    assert_nil issue.addable_hearted_users.detect {|user| !issue.visible?(user)}
  end

  def test_scope_of_projects
    objects = Heart.of_projects([Project.find(1)]).order(:id).to_a
    assert_equal Heart.all.to_a, objects
  end

  def test_scope_of_projects_by_user
    hearts_issue6 = Heart.new(:heartable => Issue.find(6), :user => User.find(1))
    assert hearts_issue6.save(:validate => false)
    hearts_issue14 = Heart.new(:heartable => Issue.find(14), :user => User.find(1))
    assert hearts_issue14.save(:validate => false)

    objects = Heart.of_projects(Project.all, User.find(1)).order(:id).to_a
    assert_equal Heart.all.to_a, objects

    objects = Heart.of_projects(Project.all, User.find(3)).order(:id).to_a
    assert_equal Heart.where.not(:id => [hearts_issue6.id, hearts_issue14.id]).to_a, objects

    assert hearts_issue6.destroy
    assert hearts_issue14.destroy
  end

  def test_scope_of_projects_with_none_shall_return_none
    objects = Heart.of_projects(Project.none).order(:id).to_a
    assert_equal Heart.none, objects
  end

  def test_scope_of_projects_where_another_project
    hearts_issue4 = Heart.new(:heartable => Issue.find(4), :user => User.find(1))
    assert hearts_issue4.save(:validate => false)

    objects = Heart.of_projects([Project.find(2)]).order(:id).to_a
    assert_equal [hearts_issue4], objects

    assert hearts_issue4.destroy
  end

  def test_scope_notifications_to
    hearts_user1 = Heart.notifications_to(User.find(1))
    assert_equal hearts(:hearts_002, :hearts_008).sort, hearts_user1.sort

    hearts_user2 = Heart.notifications_to(User.find(2))
    assert_equal hearts(:hearts_001, :hearts_003, :hearts_007).sort, hearts_user2.sort

    hearts_user3 = Heart.notifications_to(User.find(3))
    assert_equal [], hearts_user3.sort
  end

  def test_any_hearted_should_return_false_if_no_object_is_hearted
    objects = (0..2).map {Issue.generate!}

    assert_equal false, Heart.any_hearted?(objects, @user)
  end

  def test_any_hearted_should_return_true_if_one_object_is_hearted
    objects = (0..2).map {Issue.generate!}
    objects.last.add_heart(@user)

    assert_equal true, Heart.any_hearted?(objects, @user)
  end

  def test_any_hearted_should_return_false_with_no_object
    assert_equal false, Heart.any_hearted?([], @user)
  end

  def test_unheart
    assert @issue.add_heart(@user)
    @issue.reload
    assert_equal 1, @issue.remove_heart(@user)
  end

  def test_prune_with_user
    Heart.where("user_id = 9").delete_all
    user = User.find(9)

    # public
    Heart.create!(:heartable => Issue.find(1), :user => user)
    Heart.create!(:heartable => Issue.find(2), :user => user)
    Heart.create!(:heartable => Board.find(1), :user => user)
    Heart.create!(:heartable => Message.find(1), :user => user)
    Heart.create!(:heartable => News.find(1), :user => user)
    Heart.create!(:heartable => Wiki.find(1), :user => user)
    Heart.create!(:heartable => WikiPage.find(2), :user => user)
    Heart.create!(:heartable => Journal.find(1), :user => user)

    # private project (id: 2)
    Member.create!(:project => Project.find(2), :principal => user, :role_ids => [1])
    Heart.create!(:heartable => Issue.find(4), :user => user)
    Heart.create!(:heartable => Board.find(3), :user => user)
    Heart.create!(:heartable => Message.find(7), :user => user)
    Heart.create!(:heartable => News.find(3), :user => user)
    Heart.create!(:heartable => Wiki.find(2), :user => user)
    Heart.create!(:heartable => WikiPage.find(3), :user => user)
    #Heart.create!(:heartable => Journal.find(_), :user => user)

    assert_no_difference 'Heart.count' do
      Heart.prune(:user => User.find(9))
    end

    Member.delete_all

    assert_difference 'Heart.count', -6 do
      Heart.prune(:user => User.find(9))
    end

    assert Issue.find(1).hearted_by?(user)
    assert !Issue.find(4).hearted_by?(user)
  end

  def test_prune_with_project
    user = User.find(9)
    Heart.new(:heartable => Issue.find(4), :user => User.find(9)).save(:validate => false) # project 2
    Heart.new(:heartable => Issue.find(6), :user => User.find(9)).save(:validate => false) # project 5

    assert Heart.prune(:project => Project.find(5)) > 0
    assert Issue.find(4).hearted_by?(user)
    assert !Issue.find(6).hearted_by?(user)
  end

  def test_prune_all
    user = User.find(9)
    Heart.new(:heartable => Issue.find(4), :user => User.find(9)).save(:validate => false)

    assert Heart.prune > 0
    assert !Issue.find(4).hearted_by?(user)
  end

  def test_hearts_to
    assert_equal hearts(:hearts_001, :hearts_003).sort, Heart.hearts_to(Issue.where(:id => 2)).sort
    assert_equal hearts(:hearts_001, :hearts_002, :hearts_003).sort, Heart.hearts_to([*(Issue.all), Message.find(1)]).sort
    assert_equal Heart.none, Heart.hearts_to(Issue.none)
  end
end

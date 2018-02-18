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

class Heart < ActiveRecord::Base
  unloadable

  belongs_to :heartable, :polymorphic => true
  belongs_to :user

  validates_presence_of :user
  validates_uniqueness_of :user_id, :scope => [:heartable_type, :heartable_id]
  validate :validate_user
  attr_protected :id

  def self.any_hearted?(objects, user)
    objects = objects.reject(&:new_record?)
    if objects.any?
      objects.group_by {|object| object.class.base_class}.each do |base_class, objects|
        if Heart.where(:heartable_type => base_class.name, :heartable_id => objects.map(&:id), :user_id => user.id).exists?
          return true
        end
      end
    end
    false
  end

  def self.prune(options={})
    if options.has_key?(:user)
      prune_single_user(options[:user], options)
    else
      pruned = 0
      User.where("id IN (SELECT DISTINCT user_id FROM #{table_name})").each do |user|
        pruned += prune_single_user(user, options)
      end
      pruned
    end
  end

  def self.hearts_to(objects)
    objects = objects.reject(&:new_record?)
    if objects.any?
      heart_conds = []
      objects.group_by {|object| object.class.base_class}.each do |base_class, objects|
        heart_conds << [
          '(heartable_type = ? AND heartable_id in (?))',
          [base_class.name, objects.map(&:id)]
        ]
      end
      Heart.where(heart_conds.map(&:first).join(" OR "),
                  *(heart_conds.map(&:last).inject([]) {|v,array| array.push(*v) }))
    else
      Heart.none
    end
  end

  protected

  def validate_user
    errors.add :user_id, :invalid unless user.nil? || user.active?
  end

  private

  def self.prune_single_user(user, options={})
    return unless user.is_a?(User)
    pruned = 0
    where(:user_id => user.id).each do |heart|
      next if heart.heartable.nil?
      if options.has_key?(:project)
        unless heart.heartable.respond_to?(:project) &&
                 heart.heartable.project == options[:project]
          next
        end
      end
      if heart.heartable.respond_to?(:visible?)
        unless heart.heartable.visible?(user)
          heart.destroy
          pruned += 1
        end
      end
    end
    pruned
  end
end

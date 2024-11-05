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

  attribute :skip_validate_user, :boolean

  validates_presence_of :user
  validates_uniqueness_of :user_id, :scope => [:heartable_type, :heartable_id]
  validate :validate_user, :unless => :skip_validate_user

  def self.of_projects(*args)
    projects = args.size > 0 ? args.shift : Project.none
    user = args.size > 0 ? args.shift : nil
    raise ArgumentError if args.size > 0

    ActiveRecord::Base.subclasses.select { |klass|
      klass.included_modules.include?(Redmine::Acts::Heartable::InstanceMethods)
    }.map { |klass|
      if user && klass.respond_to?(:visible)
        heartables = klass.visible(user)
      else
        heartables = klass.all
      end

      heartables = heartables.joins(klass.heartable_options[:joins]) if klass.heartable_options.include?(:joins)
      if klass.heartable_options[:project_key].kind_of? Proc
        heartables = klass.heartable_options[:project_key].call(heartables, projects)
      else
        heartables = heartables.where("#{klass.heartable_options[:project_key]} IN (?)", projects.map(&:id))
      end
      Heart.where(:heartable => heartables)
    }.reduce { |scope1, scope2|
      scope1.or(scope2)
    }
  end

  def self.notifications_to(user)
    raise ArgumentError unless user

    ActiveRecord::Base.subclasses.select { |klass|
      klass.included_modules.include?(Redmine::Acts::Heartable::InstanceMethods)
    }.select { |klass|
      klass.column_names.include?("author_id") || klass.column_names.include?("user_id")
    }.map { |klass|
      if klass.column_names.include?("author_id")
        Heart.where(:heartable => klass.where(:author_id => user.id))
      elsif klass.column_names.include?("user_id")
        Heart.where(:heartable => klass.where(:user_id => user.id))
      else
        Heart.none
      end
    }.reduce { |scope1, scope2|
      scope1.or(scope2)
    }
  end

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
      queries = []
      args = []
      objects.group_by {|object| object.class.base_class}.each do |base_class, objects|
        queries << '(heartable_type = ? AND heartable_id in (?))'
        args << base_class.name << objects.map(&:id)
      end
      Heart.where(queries.join(" OR "), *args)
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

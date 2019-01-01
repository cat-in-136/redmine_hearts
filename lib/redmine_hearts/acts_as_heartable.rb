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

module Redmine
  module Acts
    module Heartable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_heartable(options = {})
          return if self.included_modules.include?(Redmine::Acts::Heartable::InstanceMethods)
          options.assert_valid_keys(:project_key, :joins)

          cattr_accessor :heartable_options
          self.heartable_options = options
          self.heartable_options[:project_key] ||= "#{table_name}.project_id"

          class_eval do
            has_many :hearts, :as => :heartable, :dependent => :delete_all
            has_many :hearted_users, :through => :hearts, :source => :user, :validate => false

            scope :hearted_by, lambda { |user_id|
              joins(:hearts).
              where("#{Heart.table_name}.user_id = ?", user_id)
            }
          end
          send :include, Redmine::Acts::Heartable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def addable_hearted_users
          users = self.project.users.sort - self.hearted_users
          if respond_to?(:visible?)
            users.reject! {|user| !visible?(user)}
          end
          users
        end

        def add_heart(user)
          # Rails does not reset the has_many :through association
          hearted_users.reset
          self.hearts << Heart.new(:user => user)
        end

        def remove_heart(user)
          return nil unless user && user.is_a?(User)
          # Rails does not reset the has_many :through association
          hearted_users.reset
          hearts.where(:user_id => user.id).delete_all
        end

        def set_heart(user, heart_bool=true)
          heart_bool ? add_heart(user) : remove_heart(user)
        end

        def hearted_user_ids=(user_ids)
          if user_ids.is_a?(Array)
            user_ids = user_ids.uniq
          end
          super user_ids
        end

        def hearted_by?(user)
          !!(user && self.hearted_user_ids.detect {|uid| uid == user.id })
        end

        module ClassMethods; end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Redmine::Acts::Heartable)


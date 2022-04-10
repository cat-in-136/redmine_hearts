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

module RedmineHearts
  module HeartablePatch
    def self.included(base) # :nodoc:
      options = {}
      if base == Message
        options[:joins] = :board
        options[:project_key] = "#{Board.table_name}.project_id"
      elsif base == WikiPage
        options[:joins] = :wiki
        options[:project_key] = "#{Wiki.table_name}.project_id"
      elsif base == Journal
        options[:project_key] = Proc.new do |scope, projects|
          scope.where(:journalized => Issue.where(:project_id => projects.map(&:id)))
        end
      end
  
      base.class_eval do
        unloadable
        acts_as_heartable options
      end
    end
  end
end

Board.send(:include, RedmineHearts::HeartablePatch)
Issue.send(:include, RedmineHearts::HeartablePatch)
Message.send(:include, RedmineHearts::HeartablePatch)
News.send(:include, RedmineHearts::HeartablePatch)
Wiki.send(:include, RedmineHearts::HeartablePatch)
WikiPage.send(:include, RedmineHearts::HeartablePatch)
Journal.send(:include, RedmineHearts::HeartablePatch)

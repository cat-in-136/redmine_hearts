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

module RedmineHeartablePatch
  def self.included(base) # :nodoc:
    base.class_eval do
      unloadable
      acts_as_heartable
    end
  end
end

Board.send(:include, RedmineHeartablePatch)
Issue.send(:include, RedmineHeartablePatch)
Message.send(:include, RedmineHeartablePatch)
News.send(:include, RedmineHeartablePatch)
Wiki.send(:include, RedmineHeartablePatch)
WikiPage.send(:include, RedmineHeartablePatch)

Journal.send(:include, RedmineHeartablePatch)

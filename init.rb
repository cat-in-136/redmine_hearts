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

require_dependency 'redmine_hearts/acts_as_heartable.rb'
require_dependency 'redmine_hearts/issue_query.rb'
require_dependency 'redmine_hearts/redmine_heartable_patch.rb'
require_dependency 'redmine_hearts/view_hook.rb'

Redmine::Plugin.register :redmine_hearts do
  name 'Redmine Hearts plugin'
  author '@cat_in_136'
  description 'provide intra-Redmine Like/Fav reactions'
  version '1.0.4'
  url 'https://github.com/cat-in-136/redmine_hearts'
  author_url 'https://github.com/cat-in-136/'

  menu :application_menu, :hearts, {:controller => :hearts, :action => :index}, :caption => :hearts_link_label

  permission :hearts, { :hearts => [:index] }, :public => true
  menu :project_menu, :hearts, {:controller => :hearts, :action => :index}, :param => :project_id, :caption => :hearts_link_label
end


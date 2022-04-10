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

require File.expand_path('../lib/redmine/acts/heartable.rb', __FILE__)
require File.expand_path('../lib/redmine_hearts/heartable_patch.rb', __FILE__)
require File.expand_path('../lib/redmine_hearts/view_hook.rb', __FILE__)

Redmine::Plugin.register :redmine_hearts do
  name 'Redmine Hearts plugin'
  author '@cat_in_136'
  description 'provide intra-Redmine Like/Fav reactions'
  version '2.1.1'
  url 'https://github.com/cat-in-136/redmine_hearts'
  author_url 'https://github.com/cat-in-136/'

  menu :application_menu, :hearts, {:controller => :hearts, :action => :index}, :caption => :hearts_link_label

  permission :hearts, { :hearts => [:index] }, :public => true
  menu :project_menu, :hearts, {:controller => :hearts, :action => :index}, :param => :project_id, :caption => :hearts_link_label
end

if Rails.version > '6.0' && Rails.autoloaders.zeitwerk_enabled?
  Rails.application.config.after_initialize do
    IssueQuery.add_available_column(
      QueryAssociationColumn.new(:hearts, :count,
                                 :caption => :hearts_link_label,
                                 :default_order => 'desc',
                                 :sortable => lambda {
                                   query_str = Heart.where(:heartable_type => Issue, :heartable_id => "9999").
                                     select("COUNT(*)").
                                     to_sql.sub("9999", "#{Issue.table_name}.id")
                                   "(#{query_str})"
                                 })
    )
  end
else
  ActiveSupport::Reloader.to_prepare do
    IssueQuery.add_available_column(
      QueryAssociationColumn.new(:hearts, :count,
                                 :caption => :hearts_link_label,
                                 :default_order => 'desc',
                                 :sortable => lambda {
                                   query_str = Heart.where(:heartable_type => Issue, :heartable_id => "9999").
                                     select("COUNT(*)").
                                     to_sql.sub("9999", "#{Issue.table_name}.id")
                                   "(#{query_str})"
                                 })
    )
  end
end

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

((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
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

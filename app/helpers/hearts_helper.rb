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

module HeartsHelper

  def heart_link_with_counter(objects, user)
    objects = Array.wrap(objects)
    return '' unless objects.any?

    heart_bool = user && user.logged? && Heart.any_hearted?(objects, user)
    css = heart_bool ? 'icon icon-heart' : 'icon icon-heart-off'
    text = l(:hearts_link_label)
    url = heart_url(
      :object_type => objects.first.class.to_s.underscore,
      :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
    )
    method = heart_bool ? 'delete' : 'post'

    content_tag :span, :class => [heart_css(objects), 'heart-link-with-count'].join(' ') do
      html = String.new
      if user && user.logged?
        html << link_to(text, url, :remote => true, :method => method, :class => css)
      else
        html << content_tag(:span, text, :class => css)
      end
      html << content_tag(:span, objects.map { |v| v.hearted_users.count }.sum.to_s, :class => 'heart-count-number')
      html.html_safe
    end
  end

  def heart_css(objects)
    objects = Array.wrap(objects)
    id = (objects.size == 1 ? objects.first.id : 'bulk')
    "#{objects.first.class.to_s.underscore}-#{id}-heart"
  end
end

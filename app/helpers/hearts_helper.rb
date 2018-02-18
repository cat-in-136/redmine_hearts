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
    hearted_users_count = objects.map { |v| v.hearted_users.count }.sum

    heart_link_with_counter_manual(objects, heart_bool, hearted_users_count, user)
  end

  def multiple_heart_links_with_counters(objects, user)
    return [] unless objects.present? && objects.any?

    hearted_by_user = Heart.hearts_to(objects).where(:user => user).
      pluck(:heartable_type, :heartable_id)
    hearted_users_counts = Heart.hearts_to(objects).
      group(:heartable_type, :heartable_id).
      count

    objects.map.with_index do |object, i|
      object_type_and_id = [object.class.to_s, object.id]
      heart_bool = hearted_by_user.include?(object_type_and_id)
      hearted_users_count = hearted_users_counts[object_type_and_id] || 0

      heart_link_with_counter_manual(object, heart_bool, hearted_users_count, user)
    end
  end

  def heart_link_with_counter_manual(objects, heart_bool, hearted_users_count, user)
    objects = Array.wrap(objects)

    css = heart_bool ? 'icon icon-heart' : 'icon icon-heart-off'
    text = l(:hearts_link_label)
    url = heart_url(
      :object_type => objects.first.class.to_s.underscore,
      :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
    )
    method = heart_bool ? 'delete' : 'post'
    hearted_users_url = hearts_hearted_users_url(
      :object_type => objects.first.class.to_s.underscore,
      :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
    )

    content_tag :span, :class => [heart_css(objects), 'heart-link-with-count'].join(' ') do
      html = String.new
      if user && user.logged?
        html << link_to(text, url, :remote => true, :method => method, :class => css)
        html << link_to(hearted_users_count.to_s, hearted_users_url, :class => 'heart-count-number')
      else
        html << content_tag(:span, text, :class => css)
        html << content_tag(:span, hearted_users_count.to_s, :class => 'heart-count-number')
      end
      html.html_safe
    end
  end

  def heart_css(objects)
    objects = Array.wrap(objects)
    id = (objects.size == 1 ? objects.first.id : 'bulk')
    "#{objects.first.class.to_s.underscore}-#{id}-heart"
  end

  def link_to_heartable(object)
    case object
    when Issue
      link_to_issue object
    when Message
      link_to_message object
    when News
      link_to h(object.title), news_url(object)
    when Journal
      journal_indice = object.issue.journals.reorder(:created_on, :id).ids.index(object.id) + 1
      safe_join([
        link_to_issue(object.issue),
        ": ",
        link_to("##{object.issue.id}#note-#{journal_indice}",
                issue_url(object.issue, :anchor => "note-#{journal_indice}")),
      ], "")
    when WikiPage
      link_to h(object.title), object
    else
      link_to h(object.to_s), object
    end
  end
end

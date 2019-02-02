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
  include ERB::Util

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

    objects.map do |object|
      object_type_and_id = [object.class.to_s, object.id]
      heart_bool = hearted_by_user.include?(object_type_and_id)
      hearted_users_count = hearted_users_counts[object_type_and_id] || 0

      heart_link_with_counter_manual(object, heart_bool, hearted_users_count, user)
    end
  end

  def heart_link_with_counter_manual(objects, heart_bool, hearted_users_count, user)
    objects = Array.wrap(objects)

    css = heart_bool ? 'icon icon-heart' : 'icon icon-heart-off'
    text = content_tag :span, l(:hearts_link_label), :class => 'heart-link-label'
    object_type_and_id = {
      :object_type => objects.first.class.to_s.underscore,
      :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
    }
    url = heart_url(object_type_and_id)
    method = heart_bool ? 'delete' : 'post'
    hearted_users_url = hearts_hearted_users_url(object_type_and_id)

    content_tag :span, :class => "#{heart_css(objects)} heart-link-with-count" do
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
    when Board
      link_to h(object.name), project_board_url(object.project, object, :only_path => true)
    when Issue
      link_to_issue object
    when Message
      link_to_message object
    when News
      link_to h(object.title), news_url(object, :only_path => true)
    when Wiki
      link_to t(:label_wiki), project_wiki_url(object.project, :only_path => true)
    when WikiPage
      link_to h(object.title), object
    when Journal
      journal_indice = object.issue.journals.reorder(:created_on, :id).ids.index(object.id) + 1
      safe_join([
        link_to_issue(object.issue),
        ": ",
        link_to("##{object.issue.id}#note-#{journal_indice}",
                issue_url(object.issue, :anchor => "note-#{journal_indice}", :only_path => true)),
      ], "")
    else
      link_to h(object.to_s), object
    end
  end

  def render_api_heartable_include(heartable, api)
    api.object_type heartable.class.base_class.name.parameterize
    api.object_id heartable.id
    [:subject, :name, :title].each do |v|
      if heartable.respond_to?(v) && heartable.__send__(v).present?
        api.__send__ v, heartable.__send__(v)
        break
      end
    end
    api.project(:id => heartable.project.id, :name => heartable.project.name) if heartable.respond_to?(:project) && heartable.project.present?

    if heartable.respond_to?(:journalized_type) && heartable.journalized_type.present? &&
       heartable.respond_to?(:journalized_id) && heartable.journalized_id.present?
      api.journalized do
        api.type heartable.journalized_type
        api.id heartable.journalized_id
        api.note_index heartable.issue.journals.reorder(:created_on, :id).ids.index(heartable.id) + 1
      end
    end
  end
end

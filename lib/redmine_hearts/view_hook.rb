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

class RedmineViewHookForDevHook < Redmine::Hook::ViewListener

  def view_layouts_base_html_head(context={})
    controller = context[:controller]
    subject = heartable_subject(controller)
    if subject
      controller.send(:render_to_string, {
        :partial => "hooks/redmine_hearts/view_layouts_base_html_head",
        :locals => context.merge(:@heartable => subject)
      })
    end
  end

  def view_layouts_base_content(context={})
    controller = context[:controller]
    subject = heartable_subject(controller)
    if subject
      controller.send(:render_to_string, {
        :partial => "hooks/redmine_hearts/view_layouts_base_content",
        :locals => context.merge(:@heartable => subject)
      })
    end
  end

  def view_account_left_bottom(context={})
    heart_count = Heart.where(:user => context[:user]).count
    if heart_count > 0
      controller = context[:controller]
      controller.send(:render_to_string, {
        :partial => "hooks/redmine_hearts/view_account_left_bottom",
        :locals => context.merge(:@heart_count => heart_count)
      })
    end
  end

  private
  def heartable_subject(controller)
    subject = nil
    if (controller && (controller.action_name == 'show'))
      model_klass = controller.controller_name.classify.safe_constantize
      if model_klass && model_klass.included_modules.include?(Redmine::Acts::Heartable::InstanceMethods)
        subject = controller.instance_variable_get("@#{controller.controller_name.singularize}")
      end
    elsif ((controller.kind_of? NewsController) && (controller.action_name == 'index'))
      subject = controller.instance_variable_get(:@newss)
    end
    subject
  end
end

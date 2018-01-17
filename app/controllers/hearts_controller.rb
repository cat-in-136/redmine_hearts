# frozen_string_literal: true
#
# Redmine Hearts plugin
# Copyright (C) @cat_in_136
# Copyright (C) 2006-2017  Jean-Philippe Lang (Almost-all method code except for hearted_users are copied from redmine)
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

class HeartsController < ApplicationController
  unloadable

  def index
    @limit = 25

    scope = Heart.all
    @scope_count = scope.count
    @hearts_pages = Paginator.new @scope_count, @limit, params["page"]
    @offset ||= @hearts_pages.offset

    scope = scope.where.not(:user => User.current) unless params["including_myself"]

    @heartables = scope.group(:heartable_type, :heartable_id).
      order(:created_at => :desc).
      limit(@limit).
      offset(@offset).
      map(&:heartable)

    respond_to do |format|
      format.html
    end
  end

  before_action :require_login, :find_heartables, :only => [:heart, :unheart, :hearted_users]

  def heart
    set_heart(@heartables, User.current, true)
  end

  def unheart
    set_heart(@heartables, User.current, false)
  end

  def hearted_users
    respond_to do |format|
      format.html {
        render :hearted_users
      }
    end
  end

  private

  def find_project
    if params[:object_type] && params[:object_id]
      @heartables = find_objets_from_params
      @projects = @heartables.map(&:project).uniq
      if @heartables.size == 1
        @project = @projects.first
      end
    elsif params[:project_id]
      @project = Project.visible.find_by_param(params[:project_id])
    end
  end

  def find_heartables
    @heartables = find_objets_from_params
    unless @heartables.present?
      render_404
    end
  end

  def set_heart(heartables, user, heart_bool)
    heartables.each do |heartable|
      heartable.set_heart(user, heart_bool)
    end
    respond_to do |format|
      format.html {
        text = heart_bool ? 'Heart added.' : 'Heart removed.'
        redirect_to_referer_or {render :html => text, :status => 200, :layout => true}
      }
      format.js { render :partial => 'set_heart', :locals => {:user => user, :hearted => heartables} }
    end
  end

  def users_for_new_heart
    scope = nil
    if params[:q].blank? && @project.present?
      scope = @project.users
    else
      scope = User.all.limit(100)
    end
    users = scope.active.visible.sorted.like(params[:q]).to_a
    if @heartables && @heartables.size == 1
      users -= @heartables.first.hearted_users
    end
    users
  end

  def find_objets_from_params
    klass = Object.const_get(params[:object_type].camelcase) rescue nil
    return unless klass && klass.respond_to?('hearted_by')

    scope = klass.where(:id => Array.wrap(params[:object_id]))
    if klass.reflect_on_association(:project)
      scope = scope.preload(:project => :enabled_modules)
    end
    objects = scope.to_a

    raise Unauthorized if objects.any? do |w|
      if w.respond_to?(:visible?)
        !w.visible?
      elsif w.respond_to?(:project) && w.project
        !w.project.visible?
      end
    end
    objects
  end
end

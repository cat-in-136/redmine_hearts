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
  unloadable if respond_to?(:unloadable)

  accept_api_auth :index, :heart, :unheart, :hearted_users

  before_action :find_optional_project, :only => [:index]
  before_action :require_login, :only => [:notifications, :heart, :unheart, :hearted_users]
  before_action :find_user, :only => [:hearted_by]
  before_action :find_heartables, :only => [:heart, :unheart, :hearted_users]

  def index
    scope = Heart.of_projects(@project ? [@project] : Project.visible, User.current)
    scope = scope.where.not(:user => User.current) unless params["including_myself"]

    @days = Setting.activity_days_default.to_i
    if params[:from]
      begin; @date_to = params[:from].to_date + 1; rescue; end
    end
    @date_to ||= User.current.today + 1
    @date_from = @date_to - @days

    scope = scope.where(:created_at => @date_from...@date_to)

    @heartables_with_hearts = scope.
      order(:created_at => :desc).
      includes(:heartable, :user => :email_address).
      group_by(&:heartable)

    respond_to do |format|
      format.html
      format.api
    end
  end

  def notifications
    @user = User.current
    scope = Heart.notifications_to(@user)
    scope = scope.where.not(:user => User.current) unless params["including_myself"]

    @days = Setting.activity_days_default.to_i
    if params[:from]
      begin; @date_to = params[:from].to_date + 1; rescue; end
    end
    @date_to ||= User.current.today + 1
    @date_from = @date_to - @days

    scope = scope.where(:created_at => @date_from...@date_to)

    @heartables_with_hearts = scope.
      order(:created_at => :desc).
      includes(:heartable, :user => :email_address).
      group_by(&:heartable)

    respond_to do |format|
      format.html
      format.api
    end
  end

  def hearted_by
    @offset, @limit = api_offset_and_limit

    scope = Heart.where(:user => @user)
    @scope_count = scope.count
    @hearts_pages = Paginator.new @scope_count, @limit, params["page"]
    @offset ||= @hearts_pages.offset

    @hearts = scope.
      order(:created_at => :desc).
      limit(@limit).
      offset(@offset).
      includes(:heartable)

    respond_to do |format|
      format.html
      format.api
    end
  end

  def heart
    set_heart(@heartables, User.current, true)
  end

  def unheart
    set_heart(@heartables, User.current, false)
  end

  def hearted_users
    respond_to do |format|
      format.html
      format.api
    end
  end

  private

  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    check_project_privacy if @project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

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
      format.api { render_api_head :no_content } # api_ok
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

  def find_user
    @user = User.find(params[:user_id]) rescue nil
    unless @user.present?
      render_404
    end
  end
end

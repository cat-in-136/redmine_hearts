# frozen_string_literal: true
# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + "/../../../test/test_helper")

module Redmine
  module PluginFixtureSetLoader
    def self.included(base)
      base.class_eval do
        def self.plugin_fixtures(*fixture_set_names)
          fixture_sets = ActiveRecord::FixtureSet.create_fixtures(File.join(File.dirname(__FILE__), "fixtures"), fixture_set_names)
          methods = Module.new do
            fixture_sets.each do |fixture_set|
              fs_name = fixture_set.name
              accessor_name = fs_name.tr("/", "_").to_sym

              define_method(accessor_name) do |*fixture_names|
                return_single_record = fixture_names.size == 1

                instances = fixture_names.map do |f_name|
                  f_name = f_name.to_s if f_name.is_a?(Symbol)
                  fixture = fixture_set.fixtures[f_name]
                  unless fixture
                    raise StandardError, "No fixture named '#{f_name}' found for fixture set '#{fs_name}'"
                  end
                  fixture.find
                end

                return_single_record ? instances.first : instances
              end
              private accessor_name
            end
          end
          include methods
        end
      end
    end
  end
end

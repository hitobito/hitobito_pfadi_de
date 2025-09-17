# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module HitobitoPfadiDe
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Set the required application version.
    app_requirement ">= 0"

    # Add a load path for this specific wagon
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
    ]

    config.to_prepare do
      # :group_and_below_efz may manage the SGB VIII EFZ qualifications of people
      Role::Permissions << :group_and_below_efz

      # extend application classes here
      Role.include PfadiDe::Role
      Group.include PfadiDe::Group
      Person.prepend PfadiDe::Person
      Contactable.include PfadiDe::Contactable

      GroupsController.prepend PfadiDe::GroupsController
      PeopleController.prepend PfadiDe::PeopleController

      Wizards::Steps::NewUserForm.support_company = false

      PersonResource.prepend PfadiDe::PersonResource
      GroupResource.prepend PfadiDe::GroupResource

      Export::Tabular::People::PeopleAddress.prepend PfadiDe::Export::Tabular::People::PeopleAddress
    end

    initializer "pfadi_de.add_settings" do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.reload!
    end

    initializer "pfadi_de.add_inflections" do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        # inflect.irregular "census", "censuses"
      end
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)] # rubocop:disable Rails/EnvironmentVariableAccess -- This is initialization
    end
  end
end

# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
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

    config.to_prepare do # rubocop:disable Metrics/BlockLength
      JobManager.wagon_jobs += [
        PfadiDe::RecalculateLastEntryDatesJob,
        PfadiDe::RecalculateRecentEntryDatesJob
      ]

      # :group_and_below_efz may manage the SGB VIII EFZ qualifications of people
      Role::Permissions << :group_and_below_efz << :assign_restricted_fee_kinds

      # extend application classes here
      Role.include PfadiDe::Role
      Group.include PfadiDe::Group
      Person.prepend PfadiDe::Person
      Contactable.include PfadiDe::Contactable
      ServiceToken.prepend PfadiDe::ServiceToken

      VariousAbility.include PfadiDe::VariousAbility
      InvoiceAbility.include PfadiDe::InvoiceAbility
      TokenAbility.prepend PfadiDe::ApiScopeAbility
      DoorkeeperTokenAbility.prepend PfadiDe::ApiScopeAbility

      GroupsController.prepend PfadiDe::GroupsController
      PeopleController.prepend PfadiDe::PeopleController
      RolesController.prepend PfadiDe::RolesController
      PeriodInvoiceTemplatesController.prepend PfadiDe::PeriodInvoiceTemplatesController
      ServiceTokensController.permitted_attrs += [:fee_kinds]

      GroupDecorator.prepend PfadiDe::GroupDecorator

      Wizards::RegisterNewUserWizard.prepend PfadiDe::Wizards::RegisterNewUserWizard
      Wizards::Steps::NewUserForm.prepend PfadiDe::Wizards::Steps::NewUserForm

      PersonResource.prepend PfadiDe::PersonResource
      GroupResource.prepend PfadiDe::GroupResource
      RoleResource.prepend PfadiDe::RoleResource
      SelfRegistrationResource.prepend PfadiDe::SelfRegistrationResource

      Export::Tabular::People::PeopleAddress.prepend PfadiDe::Export::Tabular::People::PeopleAddress
      Export::Pdf::Invoice.runner = Export::Pdf::Invoice::RunnerWithProcessedSubjects

      NavigationHelper::MAIN.find { _1[:label] == :groups }[:inactive_for].push("fee_kinds")
      NavigationHelper::MAIN.find { _1[:label] == :invoices }[:active_for].push("fee_kinds")

      TableDisplay.register_column(Person,
        TableDisplays::People::FeeKindColumn,
        :fee_kind)
    end

    initializer "pfadi_de.add_settings" do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "reset-languages.yml"))
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.reload!

      if Rails.env.test?
        Rails.application.configure do
          default_url_options.delete(:locale)
        end
      end
    end

    initializer "pfadi_de.add_inflections" do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.irregular "rechtsform", "rechtsformen"
        inflect.irregular "stamm_typ", "stamm_typen"
        inflect.irregular "zahlungsart", "zahlungsarten"
      end
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)] # rubocop:disable Rails/EnvironmentVariableAccess -- This is initialization
    end
  end
end

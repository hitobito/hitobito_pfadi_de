# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PersonResource
  extend ActiveSupport::Concern

  prepended do
    attribute :pronoun, :string
    attribute :entry_date, :date, writable: false, readable: :show_details_on_person? do
      @object.entry_date
    end
    attribute :exit_date, :date, readable: :show_details_on_person?
    attribute :bank_account_owner, :string, readable: :show_details_on_person?
    attribute :iban, :string, readable: :show_details_on_person?
    attribute :bic, :string, readable: :show_details_on_person?
    attribute :bank_name, :string, readable: :show_details_on_person?
    attribute :payment_method, :string, readable: :show_details_on_person?
    attribute :consent_data_retention, :boolean, readable: :show_details_on_person?

    # rubocop:disable Rails/RedundantForeignKey
    belongs_to :leading_layer, resource: GroupResource, writable: false,
      foreign_key: :leading_layer_id do
      assign do |_people, _leading_layers|
        # PfadiDe::Person#leading_layer has no setter
      end
    end
    # rubocop:enable Rails/RedundantForeignKey
  end

  # For attributes that are not viewable in the UI on an event participation of this person
  def show_details_on_person?(model_instance)
    can?(:show_details, model_instance)
  end
end

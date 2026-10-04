#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Export::Tabular::People::PeopleAddress
  extend ActiveSupport::Concern

  def initialize(list, *, **)
    if list.is_a?(ActiveRecord::Relation) && list.klass <= Person
      list = list.preload(:active_sepa_mandates)
    end
    super
  end

  private

  def person_attributes
    super + [:pronoun, :entry_date, :exit_date, :bank_account_owner, :iban, :bic, :bank_name,
      :payment_method, :sepa_mandate_references]
  end
end

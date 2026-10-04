# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::LayerGroup
  extend ActiveSupport::Concern

  SEPA_MANDATE_MODES = %w[inactive optional required].freeze

  included do
    self.used_attributes += [
      :gruendungsdatum,
      :aufloesungsdatum,
      :einsichtnahme_efz_durch_gruppe,
      :bank_account_owner,
      :iban,
      :bic,
      :bank_name,
      :debitorennummer,
      :sepa_glaeubiger_id,
      :sepa_mandate_mode,
      :zahlungsart
    ]

    i18n_enum :zahlungsart, %w[rechnung lastschrift],
      i18n_prefix: "activerecord.attributes.group.zahlungsarten"

    i18n_enum :rechtsform, %w[ev kein_ev unbekannt],
      i18n_prefix: "activerecord.attributes.group.rechtsformen"

    i18n_enum :sepa_mandate_mode, SEPA_MANDATE_MODES,
      i18n_prefix: "activerecord.attributes.group.sepa_mandate_modes"

    normalizes :sepa_glaeubiger_id, with: ->(value) { value.gsub(/\s/, "").upcase }

    validates :sepa_glaeubiger_id, sepa_creditor_identifier: true, allow_blank: true,
      if: :sepa_glaeubiger_id_changed?
    validate :assert_sepa_glaeubiger_id_for_mandates
  end

  def sepa_mandates_enabled?
    sepa_mandates_enabled_by_mode? && sepa_glaeubiger_id.present?
  end

  private

  def sepa_mandates_enabled_by_mode?
    sepa_mandate_mode.present? && sepa_mandate_mode != "inactive"
  end

  def assert_sepa_glaeubiger_id_for_mandates
    if sepa_mandates_enabled_by_mode? && sepa_glaeubiger_id.blank?
      errors.add(:sepa_mandate_mode, :sepa_glaeubiger_id_missing)
    end
  end
end

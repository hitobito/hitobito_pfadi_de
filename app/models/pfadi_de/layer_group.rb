# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::LayerGroup
  extend ActiveSupport::Concern

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
      :zahlungsart,
      :abbreviations
    ]

    # Only people with modify_superior permission (i.e. full permission on a
    # layer above) may change the abbreviations used for mailing list addresses.
    self.superior_attributes += [:abbreviations]

    validate :assert_abbreviations_unique_across_layers

    i18n_enum :zahlungsart, %w[rechnung lastschrift],
      i18n_prefix: "activerecord.attributes.group.zahlungsarten"

    i18n_enum :rechtsform, %w[ev kein_ev unbekannt],
      i18n_prefix: "activerecord.attributes.group.rechtsformen"
  end

  # Accepts either an Array or a comma/whitespace separated String so the
  # attribute can be edited through a plain text field.
  def abbreviations=(value)
    entries = value.is_a?(Array) ? value : value.to_s.split(/[,\s]+/)
    self[:abbreviations] = entries.map { |a| a.to_s.strip.downcase }.compact_blank.uniq
  end

  private

  # Abbreviations are used as mailing list address suffixes (see PfadiDe::MailingList),
  # so the same abbreviation may not be used by more than one layer.
  def assert_abbreviations_unique_across_layers
    return if abbreviations.blank?

    taken = Group.layers.where.not(id: id).where.not(abbreviations: [])
      .pluck(:abbreviations).flatten

    duplicates = abbreviations & taken
    if duplicates.any?
      errors.add(:abbreviations, :must_be_unique, values: duplicates.join(", "))
    end
  end
end

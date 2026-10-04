# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# Validates a SEPA creditor identifier (Gläubiger-Identifikationsnummer), e.g.
# DE98ZZZ09999999999: country code, two check digits, a three character creditor
# business code and the national identifier. The check digits are calculated
# according to ISO 7064 Mod 97-10, ignoring the creditor business code.
class SepaCreditorIdentifierValidator < ActiveModel::EachValidator
  FORMAT = /\A[A-Z]{2}\d{2}[A-Z0-9]{3}[A-Z0-9]{1,28}\z/
  GERMAN_FORMAT = /\ADE\d{2}[A-Z0-9]{3}\d{11}\z/

  def validate_each(record, attribute, value)
    if value.present? && !valid_creditor_identifier?(value)
      record.errors.add(attribute, :invalid_sepa_creditor_identifier)
    end
  end

  def valid_creditor_identifier?(value)
    identifier = value.delete(" ").upcase
    return false unless identifier.match?(FORMAT)
    return false if identifier.start_with?("DE") && !identifier.match?(GERMAN_FORMAT)

    rearranged = identifier[7..] + identifier[0, 4]
    numeric = rearranged.chars.map { |char| char.to_i(36).to_s }.join
    numeric.to_i % 97 == 1
  end
end

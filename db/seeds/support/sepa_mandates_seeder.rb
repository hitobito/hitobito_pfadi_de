# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# Seeds a minority of Stämme and their members with SEPA data for local development, so the
# feature can be exercised without configuring creditor ids, ibans and mandates by hand.
#
# Generated creditor ids and ibans are not random: they reuse the official Bundesbank/EPC
# sample values (DE98ZZZ09999999999 and DE89 3704 0044 0532 0130 00), varying only their last
# digit and recomputing the checksum.
class SepaMandatesSeeder
  CREDITOR_BUSINESS_CODE = "ZZZ"
  CREDITOR_NATIONAL_ID = "0999999999" # + one varying digit
  IBAN_BANK_CODE = "37040044"
  IBAN_ACCOUNT_NUMBER = "053201300" # + one varying digit

  def seed_sepa_mandates
    seed_sample(Group::Stamm.all) do |stamm, index|
      stamm.update!(sepa_mandate_mode: "optional", sepa_creditor_id: creditor_id(index))
    end

    Group::Stamm.where(sepa_mandate_mode: "optional").find_each do |stamm|
      seed_sample(people_of(stamm)) do |person, index|
        person.update!(iban: iban(index), bank_account_owner: person.to_s) if person.iban.blank?

        # SepaMandate.seed_once would skip validations (and the before_validation callback
        # that generates the reference), so idempotency is checked by hand here instead.
        next if SepaMandate.active.exists?(person_id: person.id, group_id: stamm.id)
        SepaMandate.create!(person_id: person.id, group_id: stamm.id,
          issued_at: Time.zone.now, user_confirmed_evidence_exists: true)
      end
    end
  end

  private

  def seed_sample(scope)
    records = scope.to_a
    records.sample([1, (records.size * 0.2).round].max).each.with_index { |record, index| yield record, index }
  end

  def people_of(stamm)
    Person.joins(roles: :group).where(groups: {layer_group_id: stamm.id}).distinct
  end

  def creditor_id(index)
    national_id = "#{CREDITOR_NATIONAL_ID}#{index % 10}"
    with_check_digits("#{CREDITOR_BUSINESS_CODE}#{national_id}") do |candidate|
      SepaCreditorIdentifierValidator.new(attributes: [:value]).valid_creditor_identifier?(candidate)
    end
  end

  def iban(index)
    account_number = "#{IBAN_ACCOUNT_NUMBER}#{index % 10}"
    with_check_digits("#{IBAN_BANK_CODE}#{account_number}") do |candidate|
      IbanValidator.new(attributes: [:value]).valid_iban?(candidate)
    end
  end

  # Tries every possible check digit pair and keeps the one the real validator accepts,
  # instead of reimplementing the ISO 7064 Mod 97-10 checksum a second time here. 00, 01
  # and 99 are skipped: they are reserved by ISO 13616 and alias the real check digits 97
  # steps away (our validators don't reject them, but no issuing body would ever produce them).
  def with_check_digits(bban)
    (2..98).each do |check|
      candidate = "DE#{check.to_s.rjust(2, "0")}#{bban}"
      return candidate if yield(candidate)
    end
    raise "no valid SEPA check digits found for #{bban}"
  end
end

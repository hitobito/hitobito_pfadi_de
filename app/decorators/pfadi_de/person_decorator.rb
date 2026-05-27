# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PersonDecorator
  extend ActiveSupport::Concern

  def latest_efz_einsicht_on
    einsichtnahme = efz_einsichtnahmen.order(:einsicht_on, :created_at).last
    modification_info(einsichtnahme.einsicht_on, einsichtnahme.einsichtnehmer, format: :default)
  end
end

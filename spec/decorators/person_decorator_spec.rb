# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PersonDecorator, :draper_with_helpers do
  let(:person) { Fabricate(:person).decorate }
  # let(:einsichtnehmer) { Fabricate(:person) }
  let(:current_user) { people(:admin) }

  describe "#latest_efz_einsicht_on" do
    it "returns nil when no efz_einsichtnahmen exist" do
      expect(person.latest_efz_einsicht_on).to be_nil
    end

    it "returns latest efz by issued_on" do
      Fabricate(:efz_einsichtnahme,
        person:,
        einsicht_on: 2.week.ago,
        created_at: 2.weeks.ago,
        issued_on: 3.weeks.ago)
      Fabricate(:efz_einsichtnahme,
        person:,
        einsicht_on: 1.weeks.ago,
        created_at: 1.week.ago,
        issued_on: 4.week.ago)

      # Should return the one with later issued_on (1 week ago)
      expect(person.latest_efz_einsicht_on).to include(I18n.l(2.weeks.ago.to_date))
    end
  end
end

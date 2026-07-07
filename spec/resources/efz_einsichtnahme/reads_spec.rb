# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe EfzEinsichtnahmeResource do
  let(:member) { people(:member) }
  let(:einsichtnehmer) { people(:admin) }
  let!(:efz) { Fabricate(:efz_einsichtnahme, person: member, einsichtnehmer: einsichtnehmer) }

  let(:ability) { Ability.new(people(:admin)) }

  describe "serialization" do
    context "with appropriate permission" do
      it "works" do
        render
        data = jsonapi_data[0]
        expect(data.id).to eq(efz.id)
        expect(data.jsonapi_type).to eq("efz_einsichtnahmen")
        expect(data.einsicht_on).to eq(efz.einsicht_on.to_s)
        expect(data.issued_on).to eq(efz.issued_on.to_s)
      end
    end

    context "without appropriate permission" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end
  end

  describe "including" do
    it "may include person" do
      params[:include] = "person"
      render
      person = d[0].sideload(:person)
      expect(person.id).to eq(member.id)
    end

    it "may include einsichtnehmer" do
      params[:include] = "einsichtnehmer"
      render
      person = d[0].sideload(:einsichtnehmer)
      expect(person.id).to eq(einsichtnehmer.id)
    end
  end
end

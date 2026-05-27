# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe EfzEinsichtnahme do
  let(:person) { Fabricate(:person) }
  let(:einsichtnehmer) { Fabricate(:person) }

  describe "::validations" do
    it "is valid with valid attributes" do
      efz = EfzEinsichtnahme.new(
        person: person,
        einsichtnehmer: einsichtnehmer,
        einsicht_on: Date.current,
        issued_on: 1.week.ago,
        confirmation: "1"
      )
      expect(efz).to be_valid
    end

    it "is invalid without confirmation" do
      efz = EfzEinsichtnahme.new(
        person: person,
        einsichtnehmer: einsichtnehmer,
        einsicht_on: Date.current,
        issued_on: 1.week.ago
      )
      expect(efz).not_to be_valid
      expect(efz.errors.full_messages).to eq ["Bestätigung muss akzeptiert werden"]
    end
  end

  describe "updating person#latest_efz_issued_on" do
    let(:one_week_ago) { 1.week.ago.to_date }
    let(:one_day_ago) { 1.day.ago.to_date }

    it "creating efz updates date on person" do
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_week_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_week_ago)
    end

    it "updating efz updates date on person" do
      einsichtnahme = Fabricate(:efz_einsichtnahme, person:, issued_on: one_week_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_week_ago)
      einsichtnahme.update!(issued_on: one_day_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_day_ago)
    end

    it "updates from later issued efz_einsichtnahme" do
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_week_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_week_ago)
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_day_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_day_ago)
    end

    it "updating from earlier issued efz_einsichtnahme does not update value" do
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_day_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_day_ago)
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_week_ago)
      expect(person.reload.latest_efz_issued_on).to eq(one_day_ago)
    end

    it "destroying resets value" do
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_week_ago)
      Fabricate(:efz_einsichtnahme, person:, issued_on: one_day_ago).destroy!
      expect(person.reload.latest_efz_issued_on).to eq(one_week_ago)
    end
  end
end

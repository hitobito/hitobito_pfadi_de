# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe EfzEinsichtnahmeResource, type: :resource do
  let(:member) { people(:member) }
  let(:einsichtnehmer) { people(:admin) }

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "efz_einsichtnahmen",
          attributes: {
            person_id: member.id,
            einsichtnehmer_id: einsichtnehmer.id,
            einsicht_on: "2026-01-01",
            issued_on: "2026-01-01"
          }
        }
      }
    end

    let(:instance) { EfzEinsichtnahmeResource.build(payload) }

    context "user with group_and_below_efz permission" do
      let(:role) { Fabricate(Group::Stamm::ErfassungFuehrungszeugnis.name.to_sym, group: groups(:adler)) }
      let(:ability) { Ability.new(role.person) }

      it "works" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { EfzEinsichtnahme.count }.by(1)

        efz = EfzEinsichtnahme.last
        expect(efz.person).to eq member
        expect(efz.einsichtnehmer).to eq einsichtnehmer
      end
    end

    context "without person_id" do
      let(:ability) { Ability.new(people(:admin)) }

      before { payload[:data][:attributes].delete(:person_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "without einsichtnehmer_id" do
      let(:ability) { Ability.new(people(:admin)) }

      before { payload[:data][:attributes].delete(:einsichtnehmer_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "not authorized" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "raises AccessDenied" do
        expect {
          expect(instance.save).to eq(false)
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "service token" do
      let(:token) { service_tokens(:efz_einsichtnahmen_token) }
      let(:ability) { TokenAbility.new(token) }

      it "can create when token has the efz_einsichtnahmen scope" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { EfzEinsichtnahme.count }.by(1)
      end

      it "cannot create when token is missing the efz_einsichtnahmen scope" do
        token.update!(efz_einsichtnahmen: false)
        allow(Graphiti.context[:object]).to receive(:current_ability)
          .and_return(TokenAbility.new(token))
        expect {
          expect(instance.save).to eq(true)
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "destroying" do
    let!(:efz) { Fabricate(:efz_einsichtnahme, person: member, einsichtnehmer: einsichtnehmer) }
    let(:instance) { EfzEinsichtnahmeResource.find(id: efz.id) }

    context "user with delete_efz permission" do
      let(:ability) { Ability.new(people(:admin)) }

      it "works" do
        expect {
          expect(instance.destroy).to eq(true)
        }.to change { EfzEinsichtnahme.count }.by(-1)
      end
    end

    context "not authorized" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "raises RecordNotFound" do
        expect {
          expect(instance.destroy).to eq(false)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end

    context "service token" do
      let(:token) { service_tokens(:efz_einsichtnahmen_token) }
      let(:ability) { TokenAbility.new(token) }

      it "can destroy when token has the efz_einsichtnahmen scope" do
        expect {
          expect(instance.destroy).to eq(true)
        }.to change { EfzEinsichtnahme.count }.by(-1)
      end

      it "cannot destroy when token is missing the efz_einsichtnahmen scope" do
        token.update!(efz_einsichtnahmen: false)
        expect {
          expect(instance.destroy).to eq(true)
        }.to change { EfzEinsichtnahme.count }.by(-1)
      end
    end
  end
end

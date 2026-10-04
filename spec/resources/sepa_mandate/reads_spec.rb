# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe SepaMandateResource, type: :resource do
  let(:member) { people(:member) }
  let!(:mandate) { Fabricate(:sepa_mandate, person: member, group: groups(:adler)) }
  let!(:revoked) do
    Fabricate(:sepa_mandate, person: people(:bottom_leader), group: groups(:adler)).tap(&:revoke!)
  end

  let(:ability) { Ability.new(people(:admin)) }

  describe "serialization" do
    it "works" do
      params[:filter] = {id: {eq: mandate.id}}
      render

      data = jsonapi_data[0]
      expect(data.id).to eq(mandate.id)
      expect(data.jsonapi_type).to eq("sepa_mandates")
      expect(data.reference).to eq(mandate.reference)
      expect(data.status).to eq("active")
      expect(data.person_id).to eq(member.id)
      expect(data.group_id).to eq(groups(:adler).id)
      expect(data.evidence).to eq("Hitobito-Gruppierung")
    end

    it "filters by status" do
      params[:filter] = {status: {eq: "revoked"}}
      render

      expect(jsonapi_data.map(&:id)).to eq [revoked.id]
    end

    context "as finance of the creditor layer" do
      let(:role) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group: groups(:adler)) }
      let(:ability) { Ability.new(role.person) }

      it "lists the mandates of the layer without evidence" do
        render

        expect(jsonapi_data.map(&:id)).to match_array [mandate.id, revoked.id]
        expect(jsonapi_data[0].attributes).not_to have_key("evidence")
      end
    end

    context "as the payer" do
      let(:ability) { Ability.new(member) }

      it "lists only her own mandates" do
        render

        expect(jsonapi_data.map(&:id)).to eq [mandate.id]
      end
    end

    context "without permission" do
      let(:role) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group: groups(:silberreiher)) }
      let(:ability) { Ability.new(role.person) }

      it "does not expose data" do
        render

        expect(jsonapi_data).to eq([])
      end
    end

    context "with service token" do
      let(:ability) { TokenAbility.new(service_tokens(:sepa_mandates_token)) }

      it "lists the mandates of the token layer" do
        render

        expect(jsonapi_data.map(&:id)).to match_array [mandate.id, revoked.id]
      end
    end
  end

  describe "including" do
    it "may include person and group" do
      params[:filter] = {id: {eq: mandate.id}}
      params[:include] = "person,group"
      render

      expect(d[0].sideload(:person).id).to eq(member.id)
      expect(d[0].sideload(:group).id).to eq(groups(:adler).id)
    end
  end
end

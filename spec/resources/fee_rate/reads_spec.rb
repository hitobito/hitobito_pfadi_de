# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe FeeRateResource, type: :resource do
  let(:group) { groups(:landesvorstand_bw) }
  let(:person) do
    Fabricate(:"Group::Landesvorstand::Landesschatzmeister", group: group).person
  end

  let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
  let(:fee_rate) { fee_rates(:jahresbeitragssatz) }

  it "has assumptions" do
    expect(fee_rate.fee_kind_id).to eq fee_kind.id
    expect(fee_kind.fee_rates).to include(fee_rate)

    params[:filter] = {fee_kind_id: {eq: fee_kind.id}}
    render

    expect(jsonapi_data).to be_present
  end

  describe "serialization" do
    before do
      params[:filter] = {fee_kind_id: {eq: fee_kind.id}}
    end

    it "works" do
      render
      expect(jsonapi_data.length).to eq 3
      data = jsonapi_data.find { |data| data.id == fee_rate.id }
      expect(data.jsonapi_type).to eq("fee_rates")
      expect(data.attributes["amount"]).to eq(fee_rate.amount)
    end
  end

  describe "default scoping" do
    it "only lists those valid today" do
      params[:filter] = {fee_kind_id: {eq: fee_kind.id}}

      render

      expect(d.map(&:id)).to match_array([
        fee_rates(:jahresbeitragssatz).id,
        fee_rates(:halbjahresbeitragssatz).id,
        fee_rates(:kleinkinderbeitragssatz).id
      ])

      expect(d.map(&:id)).to_not include(
        fee_rates(:alter_halbjahresbeitragssatz).id
      )
    end
  end

  describe "filtering" do
    let(:fee_rate1) { fee_rates(:halbjahresbeitragssatz) }
    let(:fee_rate2) { fee_rates(:kleinkinderbeitragssatz) }

    context "by id" do
      before do
        params[:filter] = {id: {eq: fee_rate2.id}}
      end

      it "works" do
        render
        expect(d.map(&:id)).to eq([fee_rate2.id])
      end
    end
  end

  describe "sorting" do
    describe "by id" do
      let(:fee_rate1) { fee_rates(:halbjahresbeitragssatz) }
      let(:fee_rate2) { fee_rates(:kleinkinderbeitragssatz) }
      let(:fee_rate3) { fee_rates(:jahresbeitragssatz) }
      let(:fee_rate4) { fee_rates(:alter_halbjahresbeitragssatz) }

      context "when ascending" do
        before do
          params[:sort] = "id"
        end

        it "works" do
          render
          expect(d.map(&:id)).to eq([
            fee_rate3.id,
            fee_rate1.id,
            fee_rate2.id
          ])
        end

        it "does not include expired rates" do
          render
          expect(d.map(&:id)).to_not include(fee_rate4.id)
        end
      end

      context "when descending" do
        before do
          params[:sort] = "-id"
        end

        it "works" do
          render
          expect(d.map(&:id)).to eq([
            fee_rate2.id,
            fee_rate1.id,
            fee_rate3.id
          ])
        end

        it "does not include expired rates" do
          render
          expect(d.map(&:id)).to_not include(fee_rate4.id)
        end
      end
    end
  end
end

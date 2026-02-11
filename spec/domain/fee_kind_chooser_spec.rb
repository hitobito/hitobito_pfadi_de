# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe FeeKindChooser, type: :domain do
  subject { described_class.new(role, allow_restricted) }

  context "for a role without a fee_kind" do
    let(:role) { roles(:member) }
    let(:allow_restricted) { true }

    it "defaults to nil" do
      expect(subject.default).to be_nil
    end

    it "allows nothing" do
      expect(subject.possible).to be_empty
    end
  end

  context "for a role with fee_kind" do
    let(:role) do
      roles(:paying_member).tap do |role|
        role.update_attribute!(:fee_kind_id, nil)
      end
    end

    let(:allow_restricted) { true }

    it "can return a default fee_kind" do
      expect(subject.default).to eql fee_kinds(:baden_wuerttemberg_kind)
    end

    it "can list possible (leaf) fee_kinds" do
      expect(subject.possible.map(&:name)).to match_array [
        fee_kinds(:baden_wuerttemberg_kind)
      ].map(&:name)
    end

    it "omits archived fee_kinds" do
      archived = Fabricate(
        :fee_kind,
        archived_at: 2.days.ago.to_date
      )
      expect(subject.possible).not_to include(archived)
    end
  end

  context "has edge-cases for a role with a fee_kind" do
    let(:allow_restricted) { true }
    let(:role_type) { "Group::Mitglieder::Foerdermitgliedschaft" }
    let(:current_group) { groups(:adler_mitglieder) }
    let(:current_layer) { current_group.layer_group }

    it "return a correct fee_kind with a correct role-type" do
      förder_fee_kind = Fabricate(:fee_kind, role_type: role_type)
      förder_role = Fabricate.build(role_type.to_sym, group: current_group)

      oberon = described_class.new(förder_role, allow_restricted)

      expect(oberon.default).to eql förder_fee_kind
    end

    it "tries to find a fee_kind in the current layer" do
      top_layer_fee_kind = Fabricate(:fee_kind, role_type: role_type)

      middle_layer = groups(:baden_wuerttemberg)
      middle_group = Fabricate(:"Group::Mitglieder", parent: middle_layer)
      middle_layer_fee_kind = Fabricate(:fee_kind, parent: top_layer_fee_kind, layer: middle_layer)

      lower_layer = groups(:adler)
      _lower_layer_fk = Fabricate(:fee_kind, parent: middle_layer_fee_kind, layer: lower_layer)

      middle_group_role = Fabricate.build(role_type.to_sym, group: middle_group)

      oberon = described_class.new(middle_group_role, allow_restricted)

      # assumptions
      expect(FeeKind.root_fee_kind_of(middle_layer_fee_kind).role_type).to eq role_type
      expect(middle_layer_fee_kind.layer_id).to eq middle_group_role.group.layer_group_id
      expect(oberon.send(:potential_fee_kinds)).to include(middle_layer_fee_kind)

      expect(oberon.possible).to include(middle_layer_fee_kind)
      expect(oberon.default).to eql(middle_layer_fee_kind)
    end

    it "also accepts fee_kinds without children of higher layers" do
      top_layer_fee_kind = Fabricate(:fee_kind, role_type: role_type)
      förder_role = Fabricate.build(role_type.to_sym, group: current_group)

      oberon = described_class.new(förder_role, allow_restricted)

      expect(oberon.default).to eql top_layer_fee_kind
      expect(oberon.possible).to have(1).item
    end
  end

  context "if asked by a person with fewer rights" do
    let(:role_type) { "Group::Mitglieder::Foerdermitgliedschaft" }
    let!(:restricted_kind) do
      Fabricate(:fee_kind, restricted: true, role_type: role_type)
    end
    let!(:non_restricted_kind) do
      Fabricate(:fee_kind, restricted: false, role_type: role_type)
    end

    let(:role) do
      Fabricate.build(
        role_type.to_sym,
        group: groups(:adler_mitglieder),
        fee_kind_id: nil
      )
    end

    let(:allow_restricted) { false }

    it "has assumptions" do
      # core concern
      potentials = subject.send(:potential_fee_kinds)
      expect(potentials).to_not be_empty
      expect(potentials)
        .to include(non_restricted_kind)
        .and include(restricted_kind)

      # rejection hurts, but here we go
      relevants = potentials.reject do |fk|
        fk.restricted?
      end

      expect(relevants).to_not include(restricted_kind)
      expect(relevants).to include(non_restricted_kind)

      # interaction with other rules
      possibles = subject.possible

      expect(possibles).to_not include(restricted_kind)
      expect(possibles).to include(non_restricted_kind)

      expect(possibles.map(&:name)).to eq [
        non_restricted_kind
      ].map(&:name)
    end

    it "can return a (non-restricted) default fee_kind" do
      expect(subject.default).to eq non_restricted_kind
    end

    it "can list possible fee_kinds" do
      expect(subject.possible).to eql [non_restricted_kind]
    end

    it "does not list restricted fee_kinds as possible" do
      expect(subject.default).to_not eq restricted_kind
      expect(subject.possible).to_not include(restricted_kind)
    end
  end
end

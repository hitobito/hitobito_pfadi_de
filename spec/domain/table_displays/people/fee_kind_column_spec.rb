# frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe TableDisplays::People::FeeKindColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:table) { StandardTableBuilder.new([person], self) }
  let(:person) { people(:member).decorate }
  let(:ability) { Ability.new(person) }
  let(:group) { groups(:adler_mitglieder) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(group)
  end

  context "single role with fee_kind" do
    it_behaves_like "table display", {
      column: :fee_kind,
      header: "Beitragsart",
      value: "BaWü Kind",
      permission: :show_full
    }
  end

  describe "details" do
    subject(:display) { described_class.new(ability, table: table, model_class: Person) }

    subject(:node) { Capybara::Node::Simple.new(table.to_html) }

    let(:group_bawue) { groups(:baden_wuerttemberg) }
    let(:root) { fee_kinds(:top_fee_kind) }

    before do
      allow(table).to receive(:template).at_least(:once).and_return(view)
    end

    describe "visibility" do
      it "renders fehlende Berechtigung without show_full" do
        allow(ability).to receive(:can?).and_call_original
        allow(ability).to receive(:can?).with(:show_full, person.object).and_return(false)

        display.render(:fee_kind)
        expect(node).to have_css "td", text: "fehlende Berechtigung"
      end

      it "renders the fee kind with show_full" do
        allow(ability).to receive(:can?).and_call_original
        allow(ability).to receive(:can?).with(:show_full, person.object).and_return(true)

        display.render(:fee_kind)
        expect(node).to have_css "td", text: "BaWü Kind"
      end

      it "is visible to the person herself without any special permission" do
        display.render(:fee_kind)
        expect(node).to have_css "td", text: "BaWü Kind"
      end

      it "is visible to a manager of the person without any special permission" do
        manager = Fabricate(:person)
        PeopleManager.create!(managed: person.object, manager:)

        manager_display = described_class.new(Ability.new(manager), table: table, model_class: Person)
        manager_display.render(:fee_kind)
        expect(node).to have_css "td", text: "BaWü Kind"
      end
    end

    it "renders multiple fee kinds comma sperated" do
      fee_kind = Fabricate(:fee_kind, layer: group_bawue, parent: root, name: "Other")

      Fabricate(
        Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
        group:,
        person:,
        fee_kind:
      )
      display.render(:fee_kind)
      expect(node).to have_css "td", text: "BaWü Kind, Other"
    end

    describe "restricted fee kind" do
      before do
        parent = Fabricate(:fee_kind, layer: groups(:root), name: "Restricted", restricted: true)
        fee_kind = Fabricate(:fee_kind, layer: group_bawue, parent:, name: "Other")
        Fabricate(
          Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
          group:,
          person:,
          fee_kind:
        )
        fee_kind.update_columns(restricted: true)
      end

      it "renders fehlende Berechtigung in place of name" do
        display.render(:fee_kind)
        expect(node).to have_css "td", text: "BaWü Kind, fehlende Berechtigung"
      end

      it "renders fehlende Berechtigung in place of name" do
        Fabricate(Group::Bundesvorstand::Bundesvorsitz.sti_name, group: groups(:bundesvorstand), person:)
        display.render(:fee_kind)
        expect(node).to have_css "td", text: "BaWü Kind, fehlende Berechtigung"
      end
    end
  end
end

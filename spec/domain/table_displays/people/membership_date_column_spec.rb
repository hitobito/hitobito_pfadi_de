# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe TableDisplays::People::MembershipDateColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:table) { StandardTableBuilder.new([person], self) }
  let(:person) { people(:member).decorate }
  let(:ability) { Ability.new(person) }
  let(:group) { groups(:adler_mitglieder) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(group)
  end

  context "entry_date" do
    it_behaves_like "table display", {
      column: :entry_date,
      header: "Eintrittsdatum",
      value: "01.01.2026",
      export_value: "2026-01-01",
      permission: :show_details
    }
  end

  context "exit_date" do
    it_behaves_like "table display", {
      column: :exit_date,
      header: "Austrittsdatum",
      value: "",
      permission: :show_details
    }
  end

  describe "visibility" do
    before { allow(table).to receive(:template).at_least(:once).and_return(view) }

    subject(:display) { described_class.new(ability, table: table, model_class: Person) }

    subject(:node) { Capybara::Node::Simple.new(table.to_html) }

    it "renders fehlende Berechtigung without show_details" do
      allow(ability).to receive(:can?).and_call_original
      allow(ability).to receive(:can?).with(:show_details, person.object).and_return(false)

      display.render(:entry_date)
      expect(node).to have_css "td", text: "fehlende Berechtigung"
    end
  end
end

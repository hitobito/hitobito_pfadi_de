# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

# NOTE: this deliberately does not use the shared "table display" example
# (see shared_examples.rb): that shared example's "in export" context still
# passes a real, capable template (it only omits `table:` from the *outer*
# instantiation, not from the one under test), so it can't distinguish
# "rendered in view" from "rendered for export" for a column whose output
# differs between the two (a link vs. a plain string). Real export
# (Export::Tabular::People::TableDisplayRow) instantiates columns with
# `table: nil`, which is reproduced explicitly below.
describe TableDisplays::People::MembershipGroupColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:table) { StandardTableBuilder.new([person], self) }
  let(:person) { people(:member).decorate }
  let(:ability) { Ability.new(person) }
  let(:group) { groups(:adler_mitglieder) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(group)
  end

  describe "in view" do
    subject(:display) { described_class.new(ability, table: table, model_class: Person) }

    subject(:node) { Capybara::Node::Simple.new(table.to_html) }

    before do
      allow(table).to receive(:template).at_least(:once).and_return(view)
    end

    it "requires show as permission" do
      expect(display.required_permission(:membership_group)).to eq :show
    end

    it "renders Hauptgruppierung as header" do
      display.render(:membership_group)
      expect(node).to have_css "th", text: "Hauptgruppierung"
    end

    it "renders a link to the group's page" do
      display.render(:membership_group)
      expect(node).to have_link("Adler", href: Rails.application.routes.url_helpers.group_path(
        groups(:adler)
      ))
    end

    it "is empty when person holds no active role at all" do
      roles(:paying_member).destroy
      roles(:member).destroy

      display.render(:membership_group)
      expect(node.find("td").all("*").length).to eq 0
      expect(node.find("td").text).to eq ""
    end
  end

  describe "in export" do
    # table: nil matches how Export::Tabular::People::TableDisplayRow
    # actually instantiates columns (no view context available there)
    subject(:display) { described_class.new(ability, table: nil, model_class: Person) }

    it "uses the plain group name, not a link" do
      expect(resolve_export_value(:membership_group).to_s).to eq("Adler")
    end

    it "is empty when person holds no active role at all" do
      roles(:paying_member).destroy
      roles(:member).destroy

      expect(resolve_export_value(:membership_group).to_s).to eq("")
    end

    # helper method to imitate resolving of attr usually done in TableDisplayRow
    def resolve_export_value(column)
      display.value_for(person.object, column) do |target, target_attr|
        if respond_to?(target_attr, true)
          send(target_attr)
        elsif target.respond_to?(target_attr)
          target.public_send(target_attr)
        end
      end
    end
  end
end

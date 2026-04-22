# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::FeeCalculationItem do
  let(:group) { groups(:baden_wuerttemberg) }
  let(:fee_rate_id) { fee_rates(:jahresbeitragssatz).id }
  let(:invoice) { Fabricate(:invoice, group: groups(:baden_wuerttemberg)) }
  let(:template_item_id) { 1337 }
  let(:attrs) {
    {
      invoice:,
      account: "1234",
      cost_center: "5678",
      name: "invoice item",
      dynamic_cost_parameters: {
        template_item_id:,
        fee_rate_id:,
        period_start_on: 6.months.ago,
        period_end_on: 6.months.from_now
      }
    }
  }
  let(:top_foerder_kind) {
    Fabricate(:fee_kind, layer: groups(:root),
      name: "Top Förder Kind", role_type: Group::Mitglieder::Foerdermitgliedschaft.name)
  }
  let(:land_foerder_kind) {
    Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
      name: "Land Förder Kind", parent: top_foerder_kind)
  }
  let(:foerder_kind) {
    Fabricate(:fee_kind, layer: groups(:burg_karlsruhe),
      name: "Stamm Förder Kind", parent: land_foerder_kind)
  }
  let!(:land_foerder_fee_rate) { Fabricate(:fee_rate, fee_kind: land_foerder_kind, amount: 100) }
  let!(:foerder_fee_rate) { Fabricate(:fee_rate, fee_kind: foerder_kind, amount: 200) }

  subject(:item) { described_class.for_groups(Group.none, **attrs) }

  def create_previous_invoice_item(invoice)
    InvoiceItem.create(invoice:, name: "previous", unit_cost: 1, count: 1)
  end

  context "validation" do
    before do
      # Mock the count to be greater than 0, so this validation does not distract from the rest
      item.count = 10
    end

    it "is valid with count > 0" do
      expect(item).to be_valid
    end

    it "is invalid without fee rate id" do
      item.dynamic_cost_parameters[:fee_rate_id] = nil
      expect(item).not_to be_valid
    end

    it "is invalid without period start" do
      item.dynamic_cost_parameters[:period_start_on] = nil
      expect(item).not_to be_valid
    end

    it "is valid without period end" do
      item.dynamic_cost_parameters[:period_end_on] = nil
      expect(item).to be_valid
    end

    it "is valid with nil unit_cost" do
      item.dynamic_cost_parameters[:unit_cost] = nil
      expect(item).to be_valid
    end
  end

  context "#unit_cost" do
    let(:group) { groups(:baden_wuerttemberg) }
    let!(:top_fee_rate) { Fabricate(:fee_rate, fee_kind: fee_kinds(:top_fee_kind), amount: 1000) }

    context "with relative fee rates and half-year invoice periods" do
      before do
        allow(FeatureGate).to receive(:enabled?).with("membership_fees.relative_fee_rates")
          .and_return true
        allow(FeatureGate).to receive(:enabled?).with("membership_fees.half_year_periods")
          .and_return true
      end

      it "sums all fee rates in hierarchy and divides by 2" do
        # (90 + 1000) / 2
        expect(item.unit_cost).to eq(545)
      end
    end

    context "with absolute fee rates and full-year invoice periods" do
      before do
        allow(FeatureGate).to receive(:enabled?).with("membership_fees.relative_fee_rates")
          .and_return false
        allow(FeatureGate).to receive(:enabled?).with("membership_fees.half_year_periods")
          .and_return false
      end

      it "returns only the direct fee rate's amount" do
        expect(item.unit_cost).to eq(90)
      end
    end
  end

  context "#count" do
    context "with a list of group recipients, calculating preview values for a whole invoice run" do
      let(:group) { groups(:adler_mitglieder) }
      let(:recipient_groups) { Group.where(id: [groups(:adler), groups(:burg_karlsruhe).id]) }

      subject(:item) { described_class.for_groups(recipient_groups, **attrs) }

      before do
        Group::Mitglieder::OrdentlicheMitgliedschaft.delete_all
      end

      it "counts matching people" do
        expect(item.count).to eq(0)

        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_28))

        expect(item.recalculate.count).to eq(2)
      end

      it "ignores person with inactive membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores person with future membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers person with past membership role which overlaps the period" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 12.months.ago, end_on: 1.month.ago)
        expect(item.count).to eq(1)
      end

      it "ignores person with membership role outside of the specified groups" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_31))
        expect(item.count).to eq(0)
      end

      context "with nested recipient groups" do
        let(:recipient_groups) { Group.where(id: [groups(:baden_wuerttemberg).id]) }

        it "does not count person with membership role in sub-layer" do
          Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name,
            group: groups(:adler_mitglieder))
          expect(item.count).to eq(0)
        end
      end

      it "ignores person with role of the wrong type" do
        Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:)
        expect(item.count).to eq(0)
      end

      it "counts person with membership role with child fee kind" do
        child_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: fee_kinds(:baden_wuerttemberg_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: child_fee_kind)
        expect(item.count).to eq(1)
      end

      it "counts person with membership role with grandchild fee kind" do
        grandchild_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: fee_kinds(:baden_wuerttemberg_kind))
        parent_fee_rate = Fabricate(:fee_rate, fee_kind: fee_kinds(:top_fee_kind), amount: 100)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: grandchild_fee_kind)
        item.dynamic_cost_parameters[:fee_rate_id] = parent_fee_rate.id
        invoice.group = groups(:root)
        expect(item.count).to eq(1)
      end

      it "ignores person with membership role with the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: other_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person with membership role with child fee kind of the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        child_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: other_fee_kind)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: child_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person which matches another fee rate better due to age" do
        person = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:).person
        person.update!(birthday: 5.years.ago)
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_groups(recipient_groups, **attrs.deep_merge(
          dynamic_cost_parameters: {fee_rate_id: fee_rates(:kleinkinderbeitragssatz).id}
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person which matches another fee rate better due to short membership span" do
        person = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 1.day.ago).person
        PfadiDe::RecalculateLastEntryDatesJob.new.send(:recalculate_for_person, person)
        item.dynamic_cost_parameters[:period_end_on] = 1.month.from_now
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_groups(recipient_groups, **attrs.deep_merge(
          dynamic_cost_parameters: {
            fee_rate_id: fee_rates(:halbjahresbeitragssatz).id,
            period_end_on: 1.month.from_now
          }
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person who was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: groups(:adler), group:)

        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(0)
      end

      it "counts person even when subject with different id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id + 1,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different template_item_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id + 1, recipient_type: "Group",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id, recipient_type: "Person",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts multiple membership roles of the same person and same layer as one" do
        role1 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts the first started membership role of the person, tiebreaks by lower id" do
        role1 = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          person: role1.person, start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(0)

        role2.update!(start_on: 4.weeks.ago)
        item.recalculate
        expect(item.count).to eq(1)

        role2.update!(start_on: role1.start_on)
        item.recalculate
        expect(item.count).to eq(0)
      end

      it "counts multiple membership roles of separate people separately" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end

      it "counts multiple membership roles of the same person in separate layers separately" do
        group2 = groups(:mitglieder_28)
        role1 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: group2,
          person: role1.person, start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end
    end

    context "with single group recipient" do
      let(:group) { groups(:adler_mitglieder) }
      let(:recipient_group) { groups(:adler) }

      subject(:item) { described_class.for_groups(recipient_group.id, **attrs) }

      before do
        item.invoice.recipient = recipient_group
        Group::Mitglieder::OrdentlicheMitgliedschaft.delete_all
      end

      it "counts matching people" do
        expect(item.count).to eq(0)

        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)

        expect(item.recalculate.count).to eq(2)
      end

      it "ignores person with inactive membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores person with future membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers person with past membership role which overlaps the period" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 12.months.ago, end_on: 1.month.ago)
        expect(item.count).to eq(1)
      end

      it "ignores person with membership role outside of the specified groups" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_31))
        expect(item.count).to eq(0)
      end

      context "with nested recipient groups" do
        let(:recipient_group) { groups(:baden_wuerttemberg) }

        it "does not count person with membership role in sub-layer" do
          Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name,
            group: groups(:adler_mitglieder))
          expect(item.count).to eq(0)
        end
      end

      it "ignores person with role of the wrong type" do
        Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:)
        expect(item.count).to eq(0)
      end

      it "counts person with membership role with child fee kind" do
        child_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: fee_kinds(:baden_wuerttemberg_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: child_fee_kind)
        expect(item.count).to eq(1)
      end

      it "counts person with membership role with grandchild fee kind" do
        grandchild_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: fee_kinds(:baden_wuerttemberg_kind))
        parent_fee_rate = Fabricate(:fee_rate, fee_kind: fee_kinds(:top_fee_kind), amount: 100)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: grandchild_fee_kind)
        item.dynamic_cost_parameters[:fee_rate_id] = parent_fee_rate.id
        invoice.group = groups(:root)
        expect(item.count).to eq(1)
      end

      it "ignores person with membership role with the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: other_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person with membership role with child fee kind of the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        child_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: other_fee_kind)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: child_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person which matches another fee rate better due to age" do
        person = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:).person
        person.update!(birthday: 5.years.ago)
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_groups(recipient_group.id, **attrs.deep_merge(
          dynamic_cost_parameters: {fee_rate_id: fee_rates(:kleinkinderbeitragssatz).id}
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person which matches another fee rate better due to short membership span" do
        person = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 1.day.ago).person
        PfadiDe::RecalculateLastEntryDatesJob.new.send(:recalculate_for_person, person)
        item.dynamic_cost_parameters[:period_end_on] = 1.month.from_now
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_groups(recipient_group.id, **attrs.deep_merge(
          dynamic_cost_parameters: {
            fee_rate_id: fee_rates(:halbjahresbeitragssatz).id,
            period_end_on: 1.month.from_now
          }
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person who was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: groups(:adler), group:)

        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(0)
      end

      it "counts person even when subject with different id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id + 1,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different template_item_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id + 1, recipient_type: "Group",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id, recipient_type: "Person",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts multiple membership roles of the same person and same layer as one" do
        role1 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts the first started membership role of the person, tiebreaks by lower id" do
        role1 = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          person: role1.person, start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(0)

        role2.update!(start_on: 4.weeks.ago)
        item.recalculate
        expect(item.count).to eq(1)

        role2.update!(start_on: role1.start_on)
        item.recalculate
        expect(item.count).to eq(0)
      end

      it "counts multiple membership roles of separate people separately" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end
    end

    context "with a list of person recipients, calculating preview values for an invoice run" do
      let(:group) { groups(:mitglieder_bw) }
      let(:person) { people(:member) }
      let(:person2) { people(:admin) }
      let(:recipient_people) { Person.where(id: [person.id, person2.id]) }

      subject(:item) { described_class.for_people(recipient_people, **attrs) }

      before do
        Group::Mitglieder::OrdentlicheMitgliedschaft.delete_all
        invoice.group = groups(:baden_wuerttemberg)
      end

      it "counts matching people" do
        expect(item.count).to eq(0)

        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person: person2)

        expect(item.recalculate.count).to eq(2)
      end

      it "ignores person with inactive membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores person with future membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers person with past membership role which overlaps the period" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 12.months.ago, end_on: 1.month.ago)
        expect(item.count).to eq(1)
      end

      it "ignores person with membership role outside of the specified recipient selection" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          person: people(:stammesverwaltung))
        expect(item.count).to eq(0)
      end

      context "with nested recipient groups" do
        let(:recipient_groups) { Group.where(id: [groups(:baden_wuerttemberg).id]) }

        it "does not count person with membership role in sub-layer" do
          Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, person:,
            group: groups(:adler_mitglieder))
          expect(item.count).to eq(0)
        end
      end

      it "ignores person with role of the wrong type" do
        Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:, person:)
        expect(item.count).to eq(0)
      end

      it "ignores person with membership role with the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          fee_kind: other_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person with membership role with child fee kind of the wrong fee kind" do
        other_top_fee_kind = Fabricate(:fee_kind, layer: groups(:root), name: "Top Kind 2",
          role_type: Group::Mitglieder::OrdentlicheMitgliedschaft.name)
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: other_top_fee_kind)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          fee_kind: other_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person which matches another fee rate better due to age" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        person.update!(birthday: 5.years.ago)
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_people(recipient_people, **attrs.deep_merge(
          dynamic_cost_parameters: {fee_rate_id: fee_rates(:kleinkinderbeitragssatz).id}
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person which matches another fee rate better due to short membership span" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 1.day.ago)
        PfadiDe::RecalculateLastEntryDatesJob.new.send(:recalculate_for_person, person)
        item.dynamic_cost_parameters[:period_end_on] = 1.month.from_now
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_people(recipient_people, **attrs.deep_merge(
          dynamic_cost_parameters: {
            fee_rate_id: fee_rates(:halbjahresbeitragssatz).id,
            period_end_on: 1.month.from_now
          }
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person who was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)

        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(0)
      end

      it "counts person even when subject with different id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id + 1,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different template_item_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id + 1,
          recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id, recipient_type: "Group",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts multiple membership roles of the same person and same layer as one" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts the first started membership role of the person, tiebreaks by lower id" do
        role1 = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(0)

        role2.update!(start_on: 4.weeks.ago)
        item.recalculate
        expect(item.count).to eq(1)

        role2.update!(start_on: role1.start_on)
        item.recalculate
        expect(item.count).to eq(0)
      end

      it "counts multiple membership roles of separate people separately" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person: person2,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(2)
      end
    end

    context "with single person recipient" do
      let(:group) { groups(:mitglieder_bw) }
      let(:recipient_person) { people(:member) }
      let(:person) { recipient_person }

      subject(:item) { described_class.for_people(recipient_person.id, **attrs) }

      before do
        invoice.group = groups(:baden_wuerttemberg)
        invoice.recipient = recipient_person
        Group::Mitglieder::OrdentlicheMitgliedschaft.delete_all
      end

      it "counts matching membership role" do
        expect(item.count).to eq(0)

        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)

        expect(item.recalculate.count).to eq(1)
      end

      it "ignores person with inactive membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.count).to eq(0)
      end

      it "ignores person with future membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.count).to eq(0)
      end

      it "considers person with past membership role which overlaps the period" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 12.months.ago, end_on: 1.month.ago)
        expect(item.count).to eq(1)
      end

      it "ignores member person other than the specified recipient" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          person: people(:stammesverwaltung))
        expect(item.count).to eq(0)
      end

      context "with nested recipient groups" do
        let(:recipient_groups) { Group.where(id: [groups(:baden_wuerttemberg).id]) }

        it "does not count person with membership role in sub-layer" do
          Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, person:,
            group: groups(:adler_mitglieder))
          expect(item.count).to eq(0)
        end
      end

      it "ignores person with role of the wrong type" do
        Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:, person:)
        expect(item.count).to eq(0)
      end

      it "ignores person with membership role with the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          fee_kind: other_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person with membership role with child fee kind of the wrong fee kind" do
        other_top_fee_kind = Fabricate(:fee_kind, layer: groups(:root), name: "Top Kind 2",
          role_type: Group::Mitglieder::OrdentlicheMitgliedschaft.name)
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: other_top_fee_kind)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          fee_kind: other_fee_kind)
        expect(item.count).to eq(0)
      end

      it "ignores person which matches another fee rate better due to age" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        person.update!(birthday: 5.years.ago)
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_people(recipient_person.id, **attrs.deep_merge(
          dynamic_cost_parameters: {fee_rate_id: fee_rates(:kleinkinderbeitragssatz).id}
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person which matches another fee rate better due to short membership span" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 1.day.ago)
        PfadiDe::RecalculateLastEntryDatesJob.new.send(:recalculate_for_person, person)
        item.dynamic_cost_parameters[:period_end_on] = 1.month.from_now
        expect(item.count).to eq(0)

        reduced_fee_rate_item = described_class.for_people(recipient_person.id, **attrs.deep_merge(
          dynamic_cost_parameters: {
            fee_rate_id: fee_rates(:halbjahresbeitragssatz).id,
            period_end_on: 1.month.from_now
          }
        ))
        expect(reduced_fee_rate_item.count).to eq(1)
      end

      it "ignores person who was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)

        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(0)
      end

      it "counts person even when subject with different id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id + 1,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different template_item_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id + 1)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id + 1,
          recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts person even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id, recipient_type: "Group",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.count).to eq(1)
      end

      it "counts multiple membership roles of the same person and same layer as one" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(1)
      end

      it "counts the first started membership role of the person, tiebreaks by lower id" do
        role1 = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.count).to eq(0)

        role2.update!(start_on: 4.weeks.ago)
        item.recalculate
        expect(item.count).to eq(1)

        role2.update!(start_on: role1.start_on)
        item.recalculate
        expect(item.count).to eq(0)
      end
    end
  end

  context "#build_subjects" do
    let(:role_types) { [Group::Mitglieder::OrdentlicheMitgliedschaft.name] }

    before do
      Group::Mitglieder::OrdentlicheMitgliedschaft.destroy_all
    end

    context "with single group recipient" do
      let(:group) { groups(:adler_mitglieder) }
      let(:recipient_group) { groups(:adler) }

      subject(:item) { described_class.for_groups(recipient_group.id, **attrs) }

      before do
        item.invoice.recipient = recipient_group
        Group::Mitglieder::OrdentlicheMitgliedschaft.delete_all
      end

      it "constructs attrs for creating ProcessedSubjects" do
        expect(item.subjects).to eq([])

        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        role3 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)

        expect(item.recalculate.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", template_item_id: 1337,
           item_id: item.id},
          {subject_id: role2.person_id, subject_type: "Person", template_item_id: 1337,
           item_id: item.id},
          {subject_id: role3.person_id, subject_type: "Person", template_item_id: 1337,
           item_id: item.id}
        ])
      end

      it "ignores person with inactive membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.subjects).to eq([])
      end

      it "ignores person with future membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.subjects).to eq([])
      end

      it "considers person with past membership role which overlaps the period" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 12.months.ago, end_on: 1.month.ago)
        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "ignores person with membership role outside of the specified groups" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_31))
        expect(item.subjects).to eq([])
      end

      context "with nested recipient groups" do
        let(:recipient_group) { groups(:baden_wuerttemberg) }

        it "does not count person with membership role in sub-layer" do
          Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name,
            group: groups(:adler_mitglieder))
          expect(item.subjects).to eq([])
        end
      end

      it "ignores person with role of the wrong type" do
        Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:)
        expect(item.subjects).to eq([])
      end

      it "counts person with membership role with child fee kind" do
        child_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: fee_kinds(:baden_wuerttemberg_kind))
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: child_fee_kind)
        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person with membership role with grandchild fee kind" do
        grandchild_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: fee_kinds(:baden_wuerttemberg_kind))
        parent_fee_rate = Fabricate(:fee_rate, fee_kind: fee_kinds(:top_fee_kind), amount: 100)
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: grandchild_fee_kind)
        item.dynamic_cost_parameters[:fee_rate_id] = parent_fee_rate.id
        invoice.group = groups(:root)
        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "ignores person with membership role with the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: other_fee_kind)
        expect(item.subjects).to eq([])
      end

      it "ignores person with membership role with child fee kind of the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        child_fee_kind = Fabricate(:fee_kind, layer: groups(:adler),
          name: "Adler Kind", parent: other_fee_kind)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          fee_kind: child_fee_kind)
        expect(item.subjects).to eq([])
      end

      it "ignores person which matches another fee rate better due to age" do
        person = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:).person
        person.update!(birthday: 5.years.ago)
        expect(item.subjects).to eq([])

        reduced_fee_rate_item = described_class.for_groups(recipient_group.id, **attrs.deep_merge(
          dynamic_cost_parameters: {fee_rate_id: fee_rates(:kleinkinderbeitragssatz).id}
        ))
        expect(reduced_fee_rate_item.subjects)
          .to match_array([{subject_id: person.id, subject_type: "Person", template_item_id: 1337,
                            item_id: item.id}])
      end

      it "ignores person which matches another fee rate better due to short membership span" do
        person = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 1.day.ago).person
        PfadiDe::RecalculateLastEntryDatesJob.new.send(:recalculate_for_person, person)
        item.dynamic_cost_parameters[:period_end_on] = 1.month.from_now
        expect(item.subjects).to eq([])

        reduced_fee_rate_item = described_class.for_groups(recipient_group.id, **attrs.deep_merge(
          dynamic_cost_parameters: {
            fee_rate_id: fee_rates(:halbjahresbeitragssatz).id,
            period_end_on: 1.month.from_now
          }
        ))
        expect(reduced_fee_rate_item.subjects)
          .to match_array([{subject_id: person.id, subject_type: "Person", template_item_id: 1337,
                            item_id: item.id}])
      end

      it "ignores person who was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: groups(:adler), group:)

        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.subjects).to eq([])
      end

      it "counts person even when subject with different id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id + 1,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different template_item_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient: group, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id + 1)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id + 1, recipient_type: "Group",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:)
        previous_invoice = Fabricate(:invoice, recipient_id: group.id, recipient_type: "Person",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts multiple membership roles of the same person and same layer as one" do
        role1 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person: role1.person,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([{subject_id: role1.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts the first started membership role of the person, tiebreaks by lower id" do
        role1 = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          person: role1.person, start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to eq([])

        role2.update!(start_on: 4.weeks.ago)
        item.recalculate
        expect(item.subjects).to match_array([{subject_id: role1.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])

        role2.update!(start_on: role1.start_on)
        item.recalculate
        expect(item.subjects).to eq([])
      end

      it "counts multiple membership roles of separate people separately" do
        role1 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([
          {subject_id: role1.person_id, subject_type: "Person",
           template_item_id: 1337, item_id: item.id},
          {subject_id: role2.person_id, subject_type: "Person",
           template_item_id: 1337, item_id: item.id}
        ])
      end
    end

    context "with single person recipient" do
      let(:group) { groups(:mitglieder_bw) }
      let(:recipient_person) { people(:member) }
      let(:person) { recipient_person }

      subject(:item) { described_class.for_people(recipient_person.id, **attrs) }

      before do
        invoice.group = groups(:baden_wuerttemberg)
        item.invoice.recipient = recipient_person
        Group::Mitglieder::OrdentlicheMitgliedschaft.delete_all
      end

      it "constructs attrs for creating ProcessedSubjects" do
        expect(item.subjects).to eq([])

        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)

        expect(item.recalculate.subjects).to match_array([
          {subject_id: role.person_id, subject_type: "Person", template_item_id: 1337,
           item_id: item.id}
        ])
      end

      it "ignores person with inactive membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 1.year.ago, end_on: 10.months.ago)
        expect(item.subjects).to eq([])
      end

      it "ignores person with future membership role" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 10.months.from_now, end_on: 1.year.from_now)
        expect(item.subjects).to eq([])
      end

      it "considers person with past membership role which overlaps the period" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 12.months.ago, end_on: 1.month.ago)
        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "ignores member person other than the specified recipient" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:,
          person: people(:stammesverwaltung))
        expect(item.subjects).to eq([])
      end

      context "with nested recipient groups" do
        let(:recipient_groups) { Group.where(id: [groups(:baden_wuerttemberg).id]) }

        it "does not count person with membership role in sub-layer" do
          Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, person:,
            group: groups(:adler_mitglieder))
          expect(item.subjects).to eq([])
        end
      end

      it "ignores person with role of the wrong type" do
        Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:, person:)
        expect(item.subjects).to eq([])
      end

      it "ignores person with membership role with the wrong fee kind" do
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: fee_kinds(:top_fee_kind))
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          fee_kind: other_fee_kind)
        expect(item.subjects).to eq([])
      end

      it "ignores person with membership role with child fee kind of the wrong fee kind" do
        other_top_fee_kind = Fabricate(:fee_kind, layer: groups(:root), name: "Top Kind 2",
          role_type: Group::Mitglieder::OrdentlicheMitgliedschaft.name)
        other_fee_kind = Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
          name: "BaWü Kind 2", parent: other_top_fee_kind)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          fee_kind: other_fee_kind)
        expect(item.subjects).to eq([])
      end

      it "ignores person which matches another fee rate better due to age" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        person.update!(birthday: 5.years.ago)
        expect(item.subjects).to eq([])

        reduced_fee_rate_item = described_class.for_people(recipient_person.id, **attrs.deep_merge(
          dynamic_cost_parameters: {fee_rate_id: fee_rates(:kleinkinderbeitragssatz).id}
        ))
        expect(reduced_fee_rate_item.subjects)
          .to match_array([{subject_id: person.id, subject_type: "Person", template_item_id: 1337,
                            item_id: item.id}])
      end

      it "ignores person which matches another fee rate better due to short membership span" do
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 1.day.ago)
        PfadiDe::RecalculateLastEntryDatesJob.new.send(:recalculate_for_person, person)
        item.dynamic_cost_parameters[:period_end_on] = 1.month.from_now
        expect(item.subjects).to eq([])

        reduced_fee_rate_item = described_class.for_people(recipient_person.id, **attrs.deep_merge(
          dynamic_cost_parameters: {
            fee_rate_id: fee_rates(:halbjahresbeitragssatz).id,
            period_end_on: 1.month.from_now
          }
        ))
        expect(reduced_fee_rate_item.subjects)
          .to match_array([{subject_id: person.id, subject_type: "Person", template_item_id: 1337,
                            item_id: item.id}])
      end

      it "ignores person who was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)

        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.subjects).to eq([])
      end

      it "counts person even when subject with different id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(
          subject_type: "Person", subject_id: role.person_id + 1,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id
        )

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Group", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different template_item_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient: person, group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id + 1)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different recipient_id was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id + 1,
          recipient_type: "Person", group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts person even when subject with different recipient_type was processed before" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:)
        previous_invoice = Fabricate(:invoice, recipient_id: person.id, recipient_type: "Group",
          group:)
        InvoiceRun::ProcessedSubject.create(subject_type: "Person", subject_id: role.person_id,
          item_id: create_previous_invoice_item(previous_invoice).id,
          template_item_id: template_item_id)

        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts multiple membership roles of the same person and same layer as one" do
        role = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to match_array([{subject_id: role.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])
      end

      it "counts the first started membership role of the person, tiebreaks by lower id" do
        role1 = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group:, person:,
          start_on: 3.weeks.ago, end_on: 2.weeks.ago)
        role2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group:, person:,
          start_on: 2.days.ago, end_on: 1.day.ago)
        expect(item.subjects).to eq([])

        role2.update!(start_on: 4.weeks.ago)
        item.recalculate
        expect(item.subjects).to match_array([{subject_id: role2.person_id, subject_type: "Person",
                                               template_item_id: 1337, item_id: item.id}])

        role2.update!(start_on: role1.start_on)
        item.recalculate
        expect(item.subjects).to eq([])
      end
    end
  end

  context "#dynamic_cost" do
    let(:group) { groups(:baden_wuerttemberg) }

    subject(:item) { described_class.for_groups([group.id], **attrs) }

    before do
      item.invoice.recipient = group
    end

    it "multiplies price and count" do
      Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_bw),
        fee_kind: fee_kinds(:baden_wuerttemberg_kind))
      Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_bw),
        fee_kind: fee_kinds(:baden_wuerttemberg_kind))
      expect(item.unit_cost).to eq(90)
      expect(item.count).to eq(2)
      expect(item.dynamic_cost).to eq(180.00)
    end
  end
end

# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::Role::PrerequisiteRole do
  let(:person) { people(:member) }
  let(:other_person) { people(:bottom_leader) }

  # layer: adler (Stamm)
  let(:adler_mitglieder) { groups(:adler_mitglieder) }
  # layer: burg_karlsruhe (Stamm)
  let(:karlsruhe_mitglieder) { groups(:mitglieder_28) }
  let(:mondphoenixe) { groups(:mondphoenixe) }

  # OrdentlicheMitgliedschaft of `member` in adler_mitglieder, starting 2026-01-01, open ended
  let!(:membership) { roles(:paying_member) }
  # StammGruppePfadfinder::Mitglied of `member` in pfadfinder (layer adler), starting 2025-06-03
  let!(:dependent_role) { roles(:member) }

  around do |example|
    registry = described_class.registry.dup
    example.run
    described_class.registry.replace(registry)
  end

  before do
    Group::Mitglieder::OrdentlicheMitgliedschaft.provides_role :stamm_mitgliedschaft
    Group::StammGruppePfadfinder::Mitglied
      .depends_on_role :stamm_mitgliedschaft,
        scope: :layer,
        on_uncovered: :cascade
  end

  def build_role(type, group:, person: self.person, start_on: Date.current, end_on: nil)
    type.new(person: person, group: group, start_on: start_on, end_on: end_on)
  end

  def build_dependent(**attrs)
    build_role(Group::StammGruppePfadfinder::Mitglied,
      group: groups(:pfadfinder), **attrs)
  end

  describe "coverage validation" do
    it "is valid when covered by a prerequisite role in the same layer" do
      expect(build_dependent).to be_valid
    end

    it "is valid when covered by another role type of the category" do
      Group::Mitglieder::Zweitmitgliedschaft.provides_role :stamm_mitgliedschaft
      build_role(Group::Mitglieder::Zweitmitgliedschaft, person: other_person, group: adler_mitglieder)
        .save!(validate: false)

      expect(build_dependent(person: other_person)).to be_valid
    end

    it "is invalid without any prerequisite role" do
      role = build_dependent(person: other_person)

      expect(role).not_to be_valid
      expect(role.errors[:base].first).to include("Ordentliche")
    end

    it "is invalid when the prerequisite role only exists in a different layer" do
      role = build_dependent(group: mondphoenixe)

      expect(role).not_to be_valid
    end

    it "is invalid when coverage ends before the dependent role" do
      membership.update_columns(end_on: 1.month.from_now.to_date)

      role = build_dependent(end_on: 3.months.from_now.to_date)

      expect(role).not_to be_valid
      expect(role.errors[:base].first)
        .to include(I18n.l(1.month.from_now.to_date + 1))
    end

    it "names the alternative roles and the layer in the error message" do
      Group::Mitglieder::Zweitmitgliedschaft.provides_role :stamm_mitgliedschaft
      role = build_dependent(person: other_person)

      role.valid?

      expect(role.errors[:base]).to eq [
        "Für diese Rolle wird eine Ordentliche Mitgliedschaft oder Zweitmitgliedschaft " \
        "in #{groups(:adler)} vorausgesetzt. Diese fehlt ab #{I18n.l(Date.current)}."
      ]
    end

    it "is invalid without end when the prerequisite role ends" do
      membership.update_columns(end_on: 1.month.from_now.to_date)

      role = build_dependent

      expect(role).not_to be_valid
      expect(role.errors[:base].first)
        .to end_with("Diese fehlt ab #{I18n.l(1.month.from_now.to_date + 1)}.")
    end

    it "states the uncovered period with start and end" do
      membership.update_columns(start_on: 1.month.from_now.to_date)

      role = build_dependent(end_on: 2.months.from_now.to_date)

      expect(role).not_to be_valid
      expect(role.errors[:base].first).to end_with(
        "Diese fehlt vom #{I18n.l(Date.current)} bis #{I18n.l(1.month.from_now.to_date - 1)}."
      )
    end

    it "is valid for a role entirely in the past without coverage" do
      role = build_dependent(person: other_person,
        start_on: 2.years.ago.to_date,
        end_on: 1.year.ago.to_date)

      expect(role).to be_valid
    end

    it "is covered by consecutive prerequisite roles" do
      Group::Mitglieder::Zweitmitgliedschaft.provides_role :stamm_mitgliedschaft
      membership.update_columns(end_on: 1.month.from_now.to_date)
      build_role(Group::Mitglieder::Zweitmitgliedschaft,
        group: adler_mitglieder,
        start_on: 1.month.from_now.to_date + 1)
        .save!(validate: false)

      expect(build_dependent(end_on: 3.months.from_now.to_date)).to be_valid
    end

    context "with scope :global" do
      before do
        Group::StammGruppePfadfinder::Mitglied
          .depends_on_role :stamm_mitgliedschaft,
            scope: :global,
            on_uncovered: :cascade
      end

      it "is valid with a prerequisite role in a different layer" do
        expect(build_dependent(group: mondphoenixe)).to be_valid
      end

      it "does not name a layer in the error message" do
        role = build_dependent(person: other_person)

        role.valid?

        expect(role.errors[:base].first).to eq(
          "Für diese Rolle wird eine Ordentliche Mitgliedschaft vorausgesetzt. " \
          "Diese fehlt ab #{I18n.l(Date.current)}."
        )
      end
    end

    context "with several categories" do
      before do
        Group::Mitglieder::Foerdermitgliedschaft.provides_role :dpsg_mitgliedschaft
        Group::StammGruppePfadfinder::Mitglied
          .depends_on_role :dpsg_mitgliedschaft,
            scope: :global,
            on_uncovered: :cascade
      end

      it "requires coverage in every category" do
        role = build_dependent

        expect(role).not_to be_valid
        expect(role.errors[:base].first).to include("Fördermitgliedschaft")
      end
    end
  end

  describe ".provides_role / .depends_on_role" do
    it "registers the entries in the registry" do
      expect(described_class.registry).to include(
        described_class::Provider.new(
          type: Group::Mitglieder::OrdentlicheMitgliedschaft,
          category: :stamm_mitgliedschaft
        ),
        described_class::Dependency.new(
          type: Group::StammGruppePfadfinder::Mitglied,
          category: :stamm_mitgliedschaft,
          scope: :layer,
          validate_past: false,
          on_uncovered: :cascade
        )
      )
    end

    it "is idempotent for identical declarations" do
      expect do
        Group::Mitglieder::OrdentlicheMitgliedschaft
          .provides_role :stamm_mitgliedschaft
      end.not_to change { described_class.registry.size }
    end

    it "replaces the options when the dependency is re-declared" do
      expect do
        Group::StammGruppePfadfinder::Mitglied
          .depends_on_role :stamm_mitgliedschaft,
            scope: :global,
            on_uncovered: :cascade
      end.not_to change { described_class.registry.size }

      expect(described_class.registry).to include(
        have_attributes(
          type: Group::StammGruppePfadfinder::Mitglied,
          category: :stamm_mitgliedschaft,
          scope: :global
        )
      )
    end

    it "rejects an unknown scope" do
      expect do
        Group::Mitglieder::Foerdermitgliedschaft
          .depends_on_role :other, scope: :company, on_uncovered: :cascade
      end.to raise_error(ArgumentError)
    end

    it "rejects an unknown on_uncovered" do
      expect do
        Group::Mitglieder::Foerdermitgliedschaft
          .depends_on_role :other, on_uncovered: :explode
      end.to raise_error(ArgumentError)
    end

    it "rejects validate_past: true as not implemented" do
      expect do
        Group::Mitglieder::Foerdermitgliedschaft
          .depends_on_role :other, validate_past: true, on_uncovered: :cascade
      end.to raise_error(NotImplementedError)
    end

    it "rejects on_uncovered: :prevent as not implemented" do
      expect do
        Group::Mitglieder::Foerdermitgliedschaft
          .depends_on_role :other, on_uncovered: :prevent
      end.to raise_error(NotImplementedError)
    end

    it "rejects omitted on_uncovered (default :prevent) as not implemented" do
      expect do
        Group::Mitglieder::Foerdermitgliedschaft.depends_on_role :other
      end.to raise_error(NotImplementedError)
    end

    describe "cycle detection" do
      it "rejects a direct self-dependency" do
        Group::Mitglieder::Zweitmitgliedschaft.provides_role :self_cycle

        expect do
          Group::Mitglieder::Zweitmitgliedschaft
            .depends_on_role :self_cycle, on_uncovered: :cascade
        end.to raise_error(described_class::CircularDependencyError)
      end

      it "rejects an indirect cycle" do
        Group::Mitglieder::OrdentlicheMitgliedschaft.provides_role :other_a
        Group::StammGruppePfadfinder::Mitglied
          .depends_on_role :other_a, on_uncovered: :cascade
        Group::StammGruppePfadfinder::Mitglied.provides_role :other_b

        expect do
          Group::Mitglieder::OrdentlicheMitgliedschaft
            .depends_on_role :other_b, on_uncovered: :cascade
        end.to raise_error(described_class::CircularDependencyError)
      end

      it "removes the rejected entry from the registry" do
        Group::Mitglieder::Zweitmitgliedschaft.provides_role :self_cycle

        expect do
          Group::Mitglieder::Zweitmitgliedschaft
            .depends_on_role :self_cycle, on_uncovered: :cascade
        rescue described_class::CircularDependencyError
          nil
        end.not_to change {
          described_class.registry.grep(described_class::Dependency).count { |entry| entry.category == :self_cycle }
        }
      end
    end
  end
end

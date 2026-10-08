# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe RoleAbility do
  subject(:ability) { Ability.new(user.reload) }

  let(:user) { people(:stammesverwaltung) }
  let(:today) { Date.new(2026, 4, 30) }
  let(:type) { Group::Mitglieder::OrdentlicheMitgliedschaft }
  let(:group) { groups(:adler_mitglieder) }
  let(:created_at) { today.beginning_of_day }
  let(:end_on) { nil }
  let(:role) do
    Fabricate(type.sti_name, group:, start_on: Date.new(2025, 1, 1), end_on:, created_at:)
  end

  before do
    travel_to(today.noon)
    Fabricate(:fee_kind, layer: groups(:root), role_type: Group::Mitglieder::Foerdermitgliedschaft)
  end

  [Group::Mitglieder::OrdentlicheMitgliedschaft,
    Group::Mitglieder::Foerdermitgliedschaft,
    Group::Mitglieder::Zweitmitgliedschaft].each do |membership_type|
    context "on #{membership_type.sti_name}" do
      let(:type) { membership_type }

      context "created 32 days ago" do
        let(:created_at) { 32.days.ago }

        [:update_start_on, :update_group_or_type, :hard_destroy].each do |action|
          it "may #{action}" do
            is_expected.to be_able_to(action, role)
          end
        end
      end

      context "created 33 days ago" do
        let(:created_at) { (today - 33.days).end_of_day }

        [:update_start_on, :update_group_or_type, :hard_destroy].each do |action|
          it "may not #{action}" do
            is_expected.not_to be_able_to(action, role)
          end
        end

        it "may still update the role" do
          is_expected.to be_able_to(:update, role)
        end
      end

      context "without end_on" do
        it "may update_end_on" do
          is_expected.to be_able_to(:update_end_on, role)
        end
      end

      context "with end_on in the future" do
        let(:end_on) { today + 1.year }

        it "may update_end_on" do
          is_expected.to be_able_to(:update_end_on, role)
        end
      end

      context "with end_on 32 days ago" do
        let(:end_on) { today - 32.days }

        it "may update_end_on" do
          is_expected.to be_able_to(:update_end_on, role)
        end
      end

      context "with end_on 33 days ago" do
        let(:end_on) { today - 33.days }

        it "may not update_end_on" do
          is_expected.not_to be_able_to(:update_end_on, role)
        end
      end

      it "may not end_retroactively" do
        is_expected.not_to be_able_to(:end_retroactively, role)
      end
    end
  end

  context "on non-membership role" do
    let(:type) { Group::Stamm::Stammesbeauftragt }
    let(:group) { groups(:adler) }
    let(:created_at) { 1.year.ago }
    let(:end_on) { today - 1.year }

    [:update_start_on, :update_group_or_type, :hard_destroy, :update_end_on,
      :end_retroactively].each do |action|
      it "may #{action}" do
        is_expected.to be_able_to(action, role)
      end
    end
  end

  context "as admin" do
    let(:user) { people(:admin) }
    let(:created_at) { 1.year.ago }
    let(:end_on) { today - 1.year }

    [:update_start_on, :update_group_or_type, :hard_destroy, :update_end_on,
      :end_retroactively].each do |action|
      it "may #{action}" do
        is_expected.to be_able_to(action, role)
      end
    end
  end

  context "with custom settings" do
    let(:created_at) { 11.days.ago }
    let(:end_on) { today - 6.days }

    before do
      allow(Settings.role).to receive(:change_membership_max_days).and_return(10)
      allow(Settings.role).to receive(:end_membership_max_days).and_return(5)
    end

    it "uses change_membership_max_days" do
      is_expected.not_to be_able_to(:update_start_on, role)
      is_expected.to be_able_to(:update_end_on, role)
    end
  end
end

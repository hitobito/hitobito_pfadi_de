#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FeeKind do
  context "#to_s" do
    let(:top_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
    let(:bottom_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    it "returns name" do
      expect(bottom_fee_kind.to_s).to eq bottom_fee_kind.name
    end

    it "returns name and role_type of parent when format is with_role_type" do
      expect(bottom_fee_kind.to_s(:with_role_type)).to eq "#{bottom_fee_kind.name} (Rolle)"
    end

    it "returns name and role_type when format is with_role_type and fee_kind is top layer" do
      expect(top_fee_kind.to_s(:with_role_type)).to eq "#{top_fee_kind.name} (Rolle)"
    end
  end

  context "#human_role_name" do
    let(:top_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    it "returns translated role label" do
      expect(top_fee_kind.human_role_name).to eq "Rolle"
    end
  end

  context "top layer" do
    let(:fee_kind) { fee_kinds(:top_fee_kind) }

    it "is valid" do
      expect(fee_kind).to be_valid
    end

    it "validates presence of name" do
      fee_kind.name = nil
      expect(fee_kind).not_to be_valid
    end

    it "does not validate presence of parent" do
      fee_kind.parent = nil
      expect(fee_kind).to be_valid
    end

    it "validates absence of parent" do
      fee_kind.parent = fee_kinds(:top_fee_kind)
      expect(fee_kind).not_to be_valid
    end

    it "validates presence of role_type" do
      fee_kind.role_type = nil
      expect(fee_kind).not_to be_valid
    end

    it "validates presence of restricted" do
      fee_kind.restricted = nil
      expect(fee_kind).not_to be_valid
    end

    it "cannot change role_type after create" do
      fee_kind.update!(role_type: "new_role_type")
      fee_kind.reload
      expect(fee_kind.role_type).to eq "Group::Mitglieder::OrdentlicheMitgliedschaft"
    end

    it "#restricted? returns restricted value" do
      expect(fee_kind.restricted?).to be_falsy
      fee_kind.restricted = true
      expect(fee_kind.restricted?).to be_truthy
    end
  end

  context "bottom layer" do
    let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    it "validates presence of parent" do
      fee_kind.parent = nil
      expect(fee_kind).not_to be_valid
    end

    it "validates absence of role_type" do
      fee_kind.role_type = roles(:member).type
      expect(fee_kind).not_to be_valid
    end

    it "validates absence of restricted" do
      fee_kind.restricted = false
      expect(fee_kind).not_to be_valid
    end

    it "cannot change parent_id after create" do
      fee_kind.update!(parent: Fabricate(:fee_kind))
      fee_kind.reload

      expect(fee_kind.parent).to eq fee_kinds(:top_fee_kind)
    end

    it "#restricted? returns restricted value of highest parent" do
      expect(fee_kind.restricted?).to be_falsy
      fee_kind.parent.update!(restricted: true)
      expect(fee_kind.restricted?).to be_truthy
    end
  end

  context "root_fee_kind_of" do
    let(:group_bawue) { groups(:baden_wuerttemberg) }
    let(:root) { fee_kinds(:top_fee_kind) }
    let(:level_1) { Fabricate(:fee_kind, parent: root, layer: group_bawue) }
    let(:group_level_2) { Fabricate(Group::Stamm.sti_name, parent: group_bawue) }
    let(:level_2) { Fabricate(:fee_kind, parent: level_1, layer: group_level_2) }

    it "returns nil if fee_kind has no parent" do
      expect(FeeKind.root_fee_kind_of(root)).to be root
    end

    it "returns the parent if only two levels exist" do
      result = FeeKind.root_fee_kind_of(level_1)
      expect(result).to eq(root)
    end

    it "climbs multiple levels to find the root ancestor" do
      result = FeeKind.root_fee_kind_of(level_2)

      expect(result).to eq(root)
      expect(result.parent_id).to be_nil
    end
  end

  it "validates that no parent match on create" do
    group = Fabricate(Group::Stamm.sti_name, parent: groups(:baden_wuerttemberg))
    new_fee_kind = Fabricate.build(:fee_kind, parent: fee_kinds(:top_fee_kind), layer: group)

    expect(new_fee_kind).not_to be_valid
    expect(new_fee_kind.errors.full_messages.first).to eq("Parent ist kein gültiger Wert")
    fee_kinds(:baden_wuerttemberg_kind).destroy!
    expect(new_fee_kind).to be_valid
  end

  it "allows creation of multiple fee kinds per layer with same parent" do
    expect(groups(:baden_wuerttemberg).fee_kinds.count).to eq 1
    new_fee_kind = Fabricate.build(:fee_kind,
      parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg))
    expect(new_fee_kind).to be_valid
  end

  context "#possible_fee_kind_parents" do
    let(:group) { groups(:baden_wuerttemberg) }
    let(:parent_fee_kind) { fee_kinds(:top_fee_kind) }
    let!(:fee_kind) do
      FeeKind.create(
        name: "TheLänd-Beitrag",
        layer: group.layer_group,
        parent: parent_fee_kind
      )
    end

    subject { fee_kind }

    it "returns fee kinds from all parent layers" do
      expect(fee_kind.possible_fee_kind_parents).to match_array [
        parent_fee_kind
      ]
    end

    it "does not include fee kinds for role types already covered in intermediate layers" do
      stamm = Fabricate(Group::Stamm.sti_name, parent: groups(:baden_wuerttemberg))
      stamm_fee_kind = FeeKind.build(name: "NichtHochdeutschBeitrag", layer: stamm.layer_group)

      expect(stamm_fee_kind.possible_fee_kind_parents).to_not include(parent_fee_kind)
      expect(stamm_fee_kind.possible_fee_kind_parents).to match_array [
        fee_kinds(:baden_wuerttemberg_kind),
        fee_kind
      ]
    end

    it "applies the layer-upward search separately for each role type" do
      FeeKind.destroy_all
      middle_layer = groups(:baden_wuerttemberg)
      stamm = Fabricate(Group::Stamm.sti_name, parent: middle_layer)
      role_type = "Group::Mitglieder::Foerdermitgliedschaft"
      role_type_2 = "Group::Mitglieder::OrdentlicheMitgliedschaft"
      top_layer_fee_kind_1 = Fabricate(:fee_kind, role_type: role_type)
      top_layer_fee_kind_2 = Fabricate(:fee_kind, role_type: role_type_2)
      middle_layer_fee_kind_1 = Fabricate(:fee_kind, parent: top_layer_fee_kind_1,
        layer: middle_layer)

      stamm_fee_kind = FeeKind.build(name: "NichtHochdeutschBeitrag", layer: stamm.layer_group)

      expect(stamm_fee_kind.possible_fee_kind_parents).to match_array([
        middle_layer_fee_kind_1, top_layer_fee_kind_2
      ])
    end

    it "does not include archived fee kinds" do
      parent_fee_kind.update(archived_at: 2.days.ago.to_date)

      expect(fee_kind.possible_fee_kind_parents).to_not include(parent_fee_kind)
    end

    it "does include fee kinds archived in the future" do
      parent_fee_kind.update(archived_at: 2.days.from_now.to_date)

      expect(fee_kind.possible_fee_kind_parents).to include(parent_fee_kind)
    end
  end

  context "can have many FeeRates," do
    it "but does not need to" do
      expect(fee_kinds(:top_fee_kind)).to have(0).fee_rates
    end

    it "which belong to it" do
      expect(fee_kinds(:baden_wuerttemberg_kind)).to have(4).fee_rates
    end
  end

  context "#applicable_fee_rate_condition" do
    let(:fee_kind) { Fabricate(:fee_kind) }
    let(:person) { people(:member) }
    let(:period_start_on) { Date.new(2026, 1, 1) }
    let(:period_end_on) { Date.new(2026, 12, 31) }

    subject(:applicable_fee_rate) do
      fee_kind
        .applicable_fee_rate_condition(period_start_on, period_end_on)
        .joins("INNER JOIN people ON people.id = #{person.id}")
        .first
    end

    it "returns nil when no FeeRates exist" do
      expect(applicable_fee_rate).to be_nil
    end

    it "returns the FeeRate when one FeeRate exists" do
      rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))
      result = applicable_fee_rate
      expect(result).to eq(rate)
    end

    context "active filter" do
      it "excludes FeeRates not yet valid on period_start_on" do
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: period_start_on + 1.day)
        expect(applicable_fee_rate).to be_nil
      end

      it "excludes FeeRates expired before period_start_on" do
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2024, 1, 1),
          valid_until: period_start_on - 1.day)
        expect(applicable_fee_rate).to be_nil
      end

      it "includes FeeRates valid on period_start_on regardless of person entry date" do
        rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))
        person.update!(last_entry_date_with_fee_kind: period_start_on + 1.month)
        result = applicable_fee_rate
        expect(result).to eq(rate)
      end
    end

    context "max_age filter" do
      # threshold = period_start_on - 8 years = 2018-01-01
      let(:max_age) { 8 }
      let!(:rate_with_max_age) do
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1), max_age:)
      end
      let!(:rate_without_max_age) do
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))
      end

      it "includes max_age rate when person born exactly at threshold" do
        # person born exactly at threshold 2018-01-01, qualifies (birthday <= threshold)
        person.update!(birthday: Date.new(2018, 1, 1))
        expect(applicable_fee_rate).to eq(rate_with_max_age)
      end

      it "includes max_age rate when person born after threshold" do
        # person born 2018-01-02 (one day after threshold), still qualifies
        person.update!(birthday: Date.new(2018, 1, 2))
        expect(applicable_fee_rate).to eq(rate_with_max_age)
      end

      it "excludes max_age rate when person born before threshold" do
        # person born 2017-12-31 (one day before threshold), doesn't qualify
        person.update!(birthday: Date.new(2017, 12, 31))
        expect(applicable_fee_rate).to eq(rate_without_max_age)
      end

      it "excludes max_age rate when person has no birthday (treated as old)" do
        # person with nil birthday is treated as 100 years old, doesn't qualify for max_age=8 rate
        person.update!(birthday: nil)
        expect(applicable_fee_rate).to eq(rate_without_max_age)
      end

      it "includes rate with max_age nil for any person" do
        # rate_without_max_age has max_age=nil (no age restriction)
        # person born 1980-01-01 is 46 years old, still qualifies
        person.update!(birthday: Date.new(1980, 1, 1))
        expect(applicable_fee_rate).to eq(rate_without_max_age)
      end
    end

    context "max_member_months filter" do
      # period_end_on = 2026-12-31
      # For max_member_months=6: threshold = 2026-12-31 - 6 months = 2026-06-30
      # Qualifies if reference_date >= 2026-06-30 (member joined late in period)
      let!(:half_year_rate) do
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_member_months: 6)
      end
      let!(:full_year_rate) do
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))
      end

      it "applies half-year rate when person joined exactly at threshold" do
        # entry_date 2026-07-01, within period -> reference_date = 2026-07-01
        # max_member_months=6: 2026-12-31 <= (2026-07-01 + 6 months = 2027-01-01) -> qualifies
        person.update!(last_entry_date_with_fee_kind: Date.new(2026, 7, 1))
        expect(applicable_fee_rate).to eq(half_year_rate)
      end

      it "applies half-year rate when person joined after threshold" do
        # entry_date 2026-07-02, within period -> reference_date = 2026-07-02
        # max_member_months=6: 2026-12-31 <= (2026-07-02 + 6 months = 2027-01-02) -> qualifies
        person.update!(last_entry_date_with_fee_kind: Date.new(2026, 7, 2))
        expect(applicable_fee_rate).to eq(half_year_rate)
      end

      it "applies full-year rate when person joined before threshold" do
        # entry_date 2026-06-30, within period -> reference_date = 2026-06-30
        # max_member_months=6: 2026-12-31 <= (2026-06-30 + 6 months = 2026-12-30) -> false
        # doesn't qualify for half-year rate, only full-year rate matches
        person.update!(last_entry_date_with_fee_kind: Date.new(2026, 6, 30))
        expect(applicable_fee_rate).to eq(full_year_rate)
      end

      it "applies full-year rate when person was already member before period" do
        # entry_date nil -> reference_date = period_start_on = 2026-01-01
        # max_member_months=6: 2026-12-31 <= (2026-01-01 + 6 months = 2026-07-01) -> false
        # doesn't qualify for half-year rate, only full-year rate matches
        person.update!(last_entry_date_with_fee_kind: nil)
        expect(applicable_fee_rate).to eq(full_year_rate)
      end

      it "applies full-year rate when entry_date is before period_start_on" do
        # entry_date 2025-12-31, before period -> reference_date = period_start_on = 2026-01-01
        # max_member_months=6: 2026-12-31 <= (2026-01-01 + 6 months) -> false
        person.update!(last_entry_date_with_fee_kind: period_start_on - 1.day)
        expect(applicable_fee_rate).to eq(full_year_rate)
      end

      it "applies full-year rate when entry_date is after period_end_on (fallback)" do
        # entry_date 2027-01-01, after period -> reference_date = period_start_on = 2026-01-01
        # max_member_months=6: 2026-12-31 <= (2026-01-01 + 6 months) -> false
        person.update!(last_entry_date_with_fee_kind: period_end_on + 1.day)
        expect(applicable_fee_rate).to eq(full_year_rate)
      end
    end

    context "reference_date calculation" do
      it "uses period_start_on when last_entry_date_with_fee_kind is nil" do
        # entry_date nil -> reference_date = period_start_on = 2026-01-01
        # max_member_months=11: 2026-12-31 <= (2026-01-01 + 11 months = 2026-12-01) -> false
        # doesn't qualify, no match
        person.update!(last_entry_date_with_fee_kind: nil)
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_member_months: 11)
        expect(applicable_fee_rate).to be_nil
      end

      it "uses entry_date when inside period" do
        # entry_date 2026-08-01, within period -> reference_date = 2026-08-01
        # max_member_months=5: 2026-12-31 <= (2026-08-01 + 5 months = 2027-01-01) -> qualifies
        person.update!(last_entry_date_with_fee_kind: Date.new(2026, 8, 1))
        rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_member_months: 5)
        expect(applicable_fee_rate).to eq(rate)
      end

      it "falls back to period_start_on when entry_date is after period_end_on" do
        # entry_date 2027-01-31, after period -> reference_date = period_start_on = 2026-01-01
        # max_member_months=11: 2026-12-31 <= (2026-01-01 + 11 months = 2026-12-01) -> false
        # doesn't qualify, no match
        person.update!(last_entry_date_with_fee_kind: period_end_on + 1.month)
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_member_months: 11)
        expect(applicable_fee_rate).to be_nil
      end
    end

    context "sorting" do
      it "selects max_age rate first when both max_age and max_member_months match" do
        # entry_date 2026-07-01 (at months threshold) -> reference_date = 2026-07-01
        # age threshold: 2026-07-01 - 8 years = 2018-07-01
        # person born 2018-07-01 (at age threshold), qualifies for max_age=8
        # max_member_months=6: 2026-12-31 <= (2026-07-01 + 6 months = 2027-01-01) -> qualifies
        # ORDER BY max_age ASC NULLS LAST -> age_rate (max_age=8) comes first
        person.update!(birthday: Date.new(2018, 7, 1),
          last_entry_date_with_fee_kind: Date.new(2026, 7, 1))

        age_rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_age: 8)
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_member_months: 6)
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))

        expect(applicable_fee_rate).to eq(age_rate)
      end

      it "sorts by valid_from ascending when max_age and max_member_months are equal" do
        # both rates have max_age=nil and max_member_months=nil
        # ORDER BY valid_from ASC -> older_rate (2023-01-01) comes first
        older_rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2023, 1, 1))
        Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2024, 1, 1))

        expect(applicable_fee_rate).to eq(older_rate)
      end
    end

    context "with multiple people" do
      it "returns correct rates for different people in a single query" do
        # period_start_on = 2026-01-01
        # Child born 2019-01-01 is 7 years old, qualifies for max_age: 8
        # Adult born 1980-01-01 is 46 years old, doesn't qualify for age-restricted rates
        child = Fabricate(:person, birthday: Date.new(2019, 1, 1))
        adult = Fabricate(:person, birthday: Date.new(1980, 1, 1))

        child_rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_age: 8)
        adult_rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))

        # Query both people at once using CROSS JOIN
        results = fee_kind
          .applicable_fee_rate_condition(period_start_on, period_end_on)
          .joins("CROSS JOIN people")
          .where(people: {id: [child.id, adult.id]})
          .to_a

        child_result = results.find { |r| r.person_id == child.id }
        adult_result = results.find { |r| r.person_id == adult.id }

        expect(child_result.id).to eq(child_rate.id)
        expect(adult_result.id).to eq(adult_rate.id)
      end

      it "handles people with different entry dates in a single query" do
        # period_start_on = 2026-01-01, period_end_on = 2026-12-31
        # Early joiner: 2026-01-15, reference_date = 2026-01-15, doesn't qualify for half-year
        # Late joiner: 2026-07-01, reference_date = 2026-07-01, qualifies for half-year
        # (threshold: 2026-06-30)
        early_joiner = Fabricate(:person, last_entry_date_with_fee_kind: Date.new(2026, 1, 15))
        late_joiner = Fabricate(:person, last_entry_date_with_fee_kind: Date.new(2026, 7, 1))

        half_year_rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1),
          max_member_months: 6)
        full_year_rate = Fabricate(:fee_rate, fee_kind: fee_kind, valid_from: Date.new(2025, 1, 1))

        # Query both people at once using CROSS JOIN
        results = fee_kind
          .applicable_fee_rate_condition(period_start_on, period_end_on)
          .joins("CROSS JOIN people")
          .where(people: {id: [early_joiner.id, late_joiner.id]})
          .to_a

        early_result = results.find { |r| r.person_id == early_joiner.id }
        late_result = results.find { |r| r.person_id == late_joiner.id }

        expect(early_result.id).to eq(full_year_rate.id)
        expect(late_result.id).to eq(half_year_rate.id)
      end
    end
  end
end

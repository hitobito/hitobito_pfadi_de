# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe SepaMandateAbility do
  let(:member) { people(:member) }
  let(:creditor) { groups(:adler) }
  let(:mandate) { SepaMandate.new(person: member, group: creditor) }

  def ability_for(role, group_key)
    group = groups(group_key)
    role = Fabricate.build([group.type, role].join("::"), group:)
    Ability.new(Fabricate.build(:person, roles: [role]))
  end

  describe "read" do
    it "may be read by the payer herself" do
      expect(Ability.new(member)).to be_able_to(:show, mandate)
    end

    it "may not be read by other members of the group" do
      expect(ability_for("Mitglied", :pfadfinder)).not_to be_able_to(:show, mandate)
    end

    it "may not be read with group_read only (no full permission)" do
      expect(ability_for("Leitung", :pfadfinder)).not_to be_able_to(:show, mandate)
    end

    it "may not be read with read-only permissions in the layer of the person" do
      expect(ability_for("Stammesfuehrung", :adler)).not_to be_able_to(:show, mandate)
    end

    it "may be read with layer_and_below_full on the creditor layer" do
      expect(ability_for("Stammesmitgliederverwaltung", :adler)).to be_able_to(:show, mandate)
    end

    it "may be read with layer_and_below_full above the creditor layer" do
      expect(ability_for("Landesmitgliederverwaltung", :baden_wuerttemberg))
        .to be_able_to(:show, mandate)
    end

    it "may not be read with layer_and_below_full in another layer" do
      expect(ability_for("Stammesmitgliederverwaltung", :silberreiher))
        .not_to be_able_to(:show, mandate)
    end

    it "may not be read with full permissions on the person but not on the creditor" do
      mandate.group = groups(:silberreiher)
      expect(ability_for("Stammesmitgliederverwaltung", :adler)).not_to be_able_to(:show, mandate)
    end

    it "may be read with finance on the creditor layer" do
      expect(ability_for("Stammesschatzmeister", :adler)).to be_able_to(:show, mandate)
    end

    it "may not be read with finance in a layer above the creditor" do
      expect(ability_for("Landesschatzmeister", :landesvorstand_bw)).not_to be_able_to(:show, mandate)
    end

    it "may be listed for the person with finance in the person's layer" do
      expect(ability_for("Stammesschatzmeister", :adler))
        .to be_able_to(:index, SepaMandate.new(person: member))
    end
  end

  describe "create" do
    it "may be created with finance on the creditor layer" do
      expect(ability_for("Stammesschatzmeister", :adler)).to be_able_to(:create, mandate)
    end

    it "may be created with finance above the creditor layer" do
      expect(ability_for("Landesschatzmeister", :landesvorstand_bw)).to be_able_to(:create, mandate)
    end

    it "may not be created with finance in another layer" do
      expect(ability_for("Stammesschatzmeister", :silberreiher)).not_to be_able_to(:create, mandate)
    end

    it "may not be created for a person outside of the creditor layer" do
      mandate.group = groups(:silberreiher)
      expect(ability_for("Landesschatzmeister", :landesvorstand_bw)).not_to be_able_to(:create, mandate)
    end

    it "may not be created with layer_and_below_full" do
      expect(ability_for("Stammesmitgliederverwaltung", :adler)).not_to be_able_to(:create, mandate)
    end

    it "may not be created by the payer herself" do
      expect(Ability.new(member)).not_to be_able_to(:create, mandate)
    end
  end

  describe "revoke" do
    it "may be revoked with finance on the creditor layer" do
      expect(ability_for("Stammesschatzmeister", :adler)).to be_able_to(:revoke, mandate)
    end

    it "may be revoked with layer_and_below_full on the creditor layer" do
      expect(ability_for("Stammesmitgliederverwaltung", :adler)).to be_able_to(:revoke, mandate)
    end

    it "may be revoked with layer_and_below_full above the creditor layer" do
      expect(ability_for("Landesmitgliederverwaltung", :baden_wuerttemberg))
        .to be_able_to(:revoke, mandate)
    end

    it "may not be revoked with layer_and_below_full in another layer" do
      expect(ability_for("Stammesmitgliederverwaltung", :silberreiher))
        .not_to be_able_to(:revoke, mandate)
    end

    it "may not be revoked with read permissions only" do
      expect(ability_for("Stammesfuehrung", :adler)).not_to be_able_to(:revoke, mandate)
    end

    it "may not be revoked when already revoked" do
      mandate.revoked_at = Time.zone.now
      expect(ability_for("Stammesschatzmeister", :adler)).not_to be_able_to(:revoke, mandate)
    end
  end

  describe "destroy and evidence" do
    it "is allowed for admins" do
      expect(Ability.new(people(:admin))).to be_able_to(:destroy, mandate)
      expect(Ability.new(people(:admin))).to be_able_to(:show_evidence, mandate)
    end

    it "is not allowed with finance" do
      expect(ability_for("Stammesschatzmeister", :adler)).not_to be_able_to(:destroy, mandate)
      expect(ability_for("Stammesschatzmeister", :adler)).not_to be_able_to(:show_evidence, mandate)
    end
  end
end

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe GroupDecorator, :draper_with_helpers do
  subject(:decorator) { GroupDecorator.new(model) }

  context "for Bundesebene" do
    let(:model) { groups(:root) }

    it "shows button for group recipients" do
      expect(decorator.show_new_period_invoice_template_for_groups?).to be_truthy
    end

    it "shows button for people recipients" do
      expect(decorator.show_new_period_invoice_template_for_people?).to be_truthy
    end
  end

  context "for Landesverband" do
    let(:model) { groups(:baden_wuerttemberg) }

    it "shows button for group recipients" do
      expect(decorator.show_new_period_invoice_template_for_groups?).to be_truthy
    end

    it "shows button for people recipients" do
      expect(decorator.show_new_period_invoice_template_for_people?).to be_truthy
    end
  end

  context "for Stamm" do
    let(:model) { groups(:adler) }

    it "does not show button for group recipients" do
      expect(decorator.show_new_period_invoice_template_for_groups?).to be_falsey
    end

    it "shows button for people recipients" do
      expect(decorator.show_new_period_invoice_template_for_people?).to be_truthy
    end
  end

  describe "#efz_verantwortliche_stelle" do
    let(:model) { groups(:adler) }
    let(:parent) { model.parent }
    let(:grandparent) { parent.parent }
    let(:root) { groups(:root) }

    before do
      allow_any_instance_of(Group).to receive(:einsichtnahme_efz_durch_gruppe).and_return(false)
      allow(model).to receive(:hierarchy).and_return([root, grandparent, parent, model])
    end

    context "when group has einsichtnahme_efz_durch_gruppe = true" do
      it "returns the group itself" do
        allow(model).to receive(:einsichtnahme_efz_durch_gruppe).and_return(true)
        expect(decorator.efz_verantwortliche_stelle).to eq(model)
      end
    end

    context "when group does not have einsichtnahme_efz_durch_gruppe" do
      it "traverses up to first parent with einsichtnahme_efz_durch_gruppe = true" do
        allow(root).to receive(:einsichtnahme_efz_durch_gruppe).and_return(true)
        allow(grandparent).to receive(:einsichtnahme_efz_durch_gruppe).and_return(true)
        expect(decorator.efz_verantwortliche_stelle).to eq(grandparent)
      end
    end

    context "when no group has einsichtnahme_efz_durch_gruppe" do
      it "returns the root of the hierarchy" do
        expect(decorator.efz_verantwortliche_stelle).to eq(root)
      end
    end
  end
end

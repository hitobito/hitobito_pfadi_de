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
end

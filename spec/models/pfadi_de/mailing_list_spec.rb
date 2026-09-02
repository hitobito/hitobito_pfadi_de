# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe MailingList do
  context "mail_name" do
    context "on a non-root layer" do
      subject { mailing_lists(:stamm_info) }

      let(:layer_group) { subject.group.layer_group }

      before { is_expected.to be_valid }

      it "accepts empty value" do
        subject.mail_name = nil
        is_expected.to be_valid

        subject.mail_name = ""
        is_expected.to be_valid
      end

      it "does not accept a mail_name without a valid suffix" do
        subject.mail_name = "info"
        is_expected.not_to be_valid
      end

      it "does not accept any mail_name if the layer has no abbreviations" do
        subject.mail_name = "info.#{layer_group.id}"

        is_expected.not_to be_valid
        expect(subject.errors[:mail_name]).to be_present
      end

      context "layer has abbreviations" do
        before do
          layer_group.abbreviations.create!(value: "Adler")
          layer_group.abbreviations.create!(value: "adl")
        end

        it "accepts mail_name ending with any configured abbreviation" do
          subject.mail_name = "info.adler"
          is_expected.to be_valid

          subject.mail_name = "info.adl"
          is_expected.to be_valid
        end

        it "does not accept mail_name ending with the layer id" do
          subject.mail_name = "info.#{layer_group.id}"
          is_expected.not_to be_valid
        end

        it "does not accept mail_name with an unrelated suffix" do
          subject.mail_name = "info.other"
          is_expected.not_to be_valid
        end
      end

      it "allows to keep old mail_name even if invalid" do
        subject.mail_name = "invalid"
        subject.save(validate: false)

        subject.name = "Some change"
        is_expected.to be_valid
      end
    end

    context "on the base (root) layer" do
      subject { mailing_lists(:info) }

      before { is_expected.to be_valid }

      it "accepts any mail_name without requiring an abbreviation" do
        subject.mail_name = "info"

        is_expected.to be_valid
      end
    end
  end
end

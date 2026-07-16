# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe People::EfzAntragsController do
  let(:group) { groups(:pfadfinder) }
  let(:person) { people(:member) }

  before { sign_in(person) }

  describe "GET#show" do
    let(:fixture_path) { HitobitoPfadiDe::Wagon.root.join("spec/fixtures/files/efz_antrag_template.pdf") }

    before do
      allow_any_instance_of(Export::Pdf::EfzAntrag).to receive(:template_path).and_return(fixture_path.to_s)
    end

    it "authorizes show permission" do
      other = Fabricate(Group::StammGruppePfadfinder::Mitglied.sti_name, group:).person
      expect do
        get :show, params: {group_id: group.id, person_id: other.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "generates inline pdf" do
      get :show, params: {group_id: group.id, person_id: person.id}
      expect(response).to be_successful
      expect(response.content_type).to eq "application/pdf"
      expect(response.headers["content-disposition"]).to eq "inline"
    end

    context "when the template is missing" do
      before do
        allow_any_instance_of(Export::Pdf::EfzAntrag)
          .to receive(:generate)
          .and_raise(Export::Pdf::EfzAntrag::TemplateNotFound, "Template not found")
      end

      it "redirects to the person profile with a flash message" do
        get :show, params: {group_id: group.id, person_id: person.id}

        expect(response).to redirect_to(group_person_path(group, person))
        expect(flash[:alert]).to eq "Die eFZ-Vorlage wurde nicht gefunden."
      end
    end
  end
end

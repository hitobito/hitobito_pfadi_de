# frozen_string_literal: true

require "spec_helper"

describe EfzEinsichtnahmenController do
  let(:person) { people(:member) }
  let(:group) { groups(:pfadfinder) }
  let(:user) { people(:admin) }

  before { sign_in(user) }

  describe "GET#new" do
    it "raises if not permitted" do
      expect do
        get :new, params: {group_id: group.id, person_id: person.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    describe "views" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }

      it "has form with required fields and assigned default value" do
        Fabricate(Group::Stamm::ErfassungFuehrungszeugnis.sti_name, person: user, group: groups(:adler))
        get :new, params: {group_id: group.id, person_id: person.id}
        expect(dom).to have_css "h1", text: "Erweitertes Führungszeugnis erfassen"
        expect(dom).to have_field "Datum der Einsicht", with: I18n.l(Time.zone.today)
        expect(dom).to have_field "Ausstellungsdatum eFZ"
        expect(dom).to have_field "Bestätigung"
        expect(dom).to have_text "keine relevanten Eintragungen im Sinne des § 72a (4) SGB VIII enthält"
      end
    end
  end

  describe "POST#create" do
    let(:valid_params) do
      {
        einsicht_on: Date.current,
        issued_on: 1.week.ago.to_date,
        confirmation: "1"
      }
    end

    it "raises if not permitted" do
      expect {
        post :create, params: {group_id: group.id, person_id: person.id, efz_einsichtnahme: valid_params}
      }.to raise_error(CanCan::AccessDenied)
    end

    it "creates a new EfzEinsichtnahme" do
      Fabricate(Group::Stamm::ErfassungFuehrungszeugnis.sti_name, person: user, group: groups(:adler))
      expect {
        post :create, params: {group_id: group.id, person_id: person.id, efz_einsichtnahme: valid_params}
      }.to change(EfzEinsichtnahme, :count).by(1)

      expect(EfzEinsichtnahme.last.einsichtnehmer).to eq(user)
      expect(response).to redirect_to(group_person_path(group, person))
    end

    it "renders new on failure" do
      Fabricate(Group::Stamm::ErfassungFuehrungszeugnis.sti_name, person: user, group: groups(:adler))
      post :create,
        params: {group_id: group.id, person_id: person.id, efz_einsichtnahme: valid_params.except(:confirmation)}
      expect(response).to render_template(:new)
    end
  end

  describe "DELETE #destroy" do
    let!(:efz) { Fabricate(:efz_einsichtnahme, person: person) }

    it "destroys the entry" do
      expect {
        delete :destroy, params: {group_id: group.id, person_id: person.id, id: efz.id}
      }.to change(EfzEinsichtnahme, :count).by(-1)
      expect(response).to redirect_to(group_person_path(group, person))
    end
  end
end

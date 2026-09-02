# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe GroupsController do
  let(:leader) { people(:stammesverwaltung) }
  let(:group) { groups(:pfadfinder) }

  before { sign_in(leader) }

  context "PUT update" do
    it "updates bank account fields" do
      put :update, params: {id: group.id, group: {
        bank_account_owner: "John Doe",
        iban: "DE00 0000 0000 0000 0000 0",
        bic: "ASDF",
        bank_name: "Finanzinstitut"
      }}
      expect(assigns(:group).bank_account_owner).to eq("John Doe")
      expect(assigns(:group).iban).to eq("DE00 0000 0000 0000 0000 0")
      expect(assigns(:group).bic).to eq("ASDF")
      expect(assigns(:group).bank_name).to eq("Finanzinstitut")
    end

    it "cannot update non used layer attribute" do
      expect do
        put :update, params: {id: group.id, group: {gruendungsdatum: Date.new(1900, 5, 1)}}
      end.not_to change { group.reload.gruendungsdatum }
    end

    context "layer group" do
      let(:group) { groups(:adler) }

      it "can update layer attribute" do
        expect do
          put :update, params: {id: group.id, group: {gruendungsdatum: Date.new(1900, 5, 1)}}
        end.to change { group.reload.gruendungsdatum }.to(Date.new(1900, 5, 1))
      end
    end

    it "may used layer_attributes on layer" do
      expect do
        put :update, params: {id: groups(:adler).id, group: {gruendungsdatum: Date.new(1900, 5, 1)}}
      end.not_to change { group.reload.gruendungsdatum }
    end

    context "abbreviations" do
      let(:group) { groups(:adler) }

      it "creates abbreviations for a user with modify_superior permission" do
        sign_in(people(:admin))

        expect do
          put :update, params: {id: group.id, group: {
            abbreviations_attributes: [{value: "Adler"}]
          }}
        end.to change { group.reload.abbreviations.map(&:value) }.from([]).to(["adler"])
      end

      it "ignores abbreviations for a user without modify_superior permission" do
        expect do
          put :update, params: {id: group.id, group: {
            abbreviations_attributes: [{value: "Adler"}]
          }}
        end.not_to change { group.reload.abbreviations.count }
      end

      it "destroys abbreviations for a user with modify_superior permission" do
        sign_in(people(:admin))
        abbreviation = group.abbreviations.create!(value: "adl")

        put :update, params: {id: group.id, group: {
          abbreviations_attributes: [{id: abbreviation.id, _destroy: true}]
        }}

        expect(group.reload.abbreviations).to be_empty
      end

      it "ignores abbreviations on a non-layer group even with modify_superior permission" do
        sign_in(people(:admin))
        non_layer_group = groups(:pfadfinder)

        expect do
          put :update, params: {id: non_layer_group.id, group: {
            abbreviations_attributes: [{value: "Pfad"}]
          }}
        end.not_to change { non_layer_group.reload.abbreviations.count }
      end
    end
  end

  describe "views" do
    render_views

    let(:layer_attrs) do
      {
        gruendungsdatum: Date.new(1900, 5, 1),
        aufloesungsdatum: Date.new(1900, 5, 1),
        einsichtnahme_efz_durch_gruppe: true,
        bank_account_owner: "owner",
        iban: "DE75512108001245126199",
        bic: "ASDF",
        bank_name: "Finanzinstitut",
        debitorennummer: 123,
        sepa_glaeubiger_id: 123,
        zahlungsart: "rechnung"
      }
    end
    let(:attrs_without_label) { [:bank_account_owner, :iban, :bic, :bank_name] }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before { group.update!(layer_attrs) }

    def label_for(attr)
      attrs_without_label.include?(attr) ? layer_attrs[attr] : Group.human_attribute_name(attr)
    end

    describe "GET#show" do
      it "does not show layer attrs" do
        get :show, params: {id: group.id}

        layer_attrs.each do |attr|
          expect(dom).not_to have_text label_for(attr)
        end
      end

      context "layer group" do
        let(:group) { groups(:adler) }

        it "does show layer attrs" do
          get :show, params: {id: group.id}

          layer_attrs.each do |attr, _value|
            expect(dom).to have_text label_for(attr)
          end
        end

        it "does not show layer attrs if blank" do
          group.update!(layer_attrs.transform_values { nil })
          get :show, params: {id: group.id}

          layer_attrs.each do |attr, _value|
            expect(dom).not_to have_text Group.human_attribute_name(attr)
          end
        end

        it "shows abbreviations" do
          group.abbreviations.create!(value: "adl")
          get :show, params: {id: group.id}

          expect(dom).to have_text Group.human_attribute_name(:abbreviations)
          expect(dom).to have_text "adl"
        end

        it "does not show the abbreviations section if there are none" do
          get :show, params: {id: group.id}

          expect(dom).not_to have_text Group.human_attribute_name(:abbreviations)
        end
      end
    end

    describe "GET#edit" do
      it "does not show layer attrs" do
        get :edit, params: {id: group.id}

        layer_attrs.each do |attr|
          expect(dom).not_to have_field Group.human_attribute_name(attr)
        end
      end

      context "layer group" do
        let(:group) { groups(:adler) }

        before do
          expect(Group::Stamm).to receive(:stamm_typ_labels).and_return(rechnungen: "Rechnungen")
        end

        it "does show layer attrs" do
          get :edit, params: {id: group.id}

          layer_attrs.keys.each do |attr|
            expect(dom).to have_field Group.human_attribute_name(attr)
          end
        end

        it "does not show the abbreviations field without modify_superior permission" do
          get :edit, params: {id: group.id}

          expect(dom).not_to have_text Group.human_attribute_name(:abbreviations)
        end

        it "shows the abbreviations field with modify_superior permission" do
          sign_in(people(:admin))
          get :edit, params: {id: group.id}

          expect(dom).to have_text Group.human_attribute_name(:abbreviations)
        end
      end
    end
  end
end

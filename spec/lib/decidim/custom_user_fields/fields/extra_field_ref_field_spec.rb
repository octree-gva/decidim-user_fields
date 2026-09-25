# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::ExtraFieldRefField do
  let(:handler_name) { "extended_data" }
  let(:options) { {} }
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:ref_me, { type: :extra_field_ref }.merge(options), handler_name) }
  let(:field) { definition.field }
  let(:form_class) do
    Class.new do
      class << self
        def attribute(*); end

        def validates(*); end
      end
    end
  end

  describe "#configure_form" do
    it "raises when customization is missing" do
      expect do
        field.configure_form(form_class)
      end.to raise_error(/customization must be set/)
    end

    it "raises when referenced field is missing from the customization" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:other, type: :dummy) }
        end
        field.customization_name = :community

        expect do
          field.configure_form(form_class)
        end.to raise_error(/not found/)
      end
    end

    it "builds a peer field under the authorization attribute name" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:ref_me, type: :dummy) }
        end
        field.customization_name = :community
        field.configure_form(form_class)

        expect(field.reference).to be_a(Decidim::CustomUserFields::FieldDefinition)
        expect(field.reference.name).to eq(:community_ref_me)
        expect(field.send(:peer_field).name).to eq(:ref_me)
      end
    end
  end

  describe "#map_model" do
    it "raises because it cannot be used on registration" do
      expect do
        field.map_model({}, {})
      end.to raise_error(Decidim::CustomUserFields::Error, /Extra Field Ref/)
    end
  end

  describe "#form_tag" do
    let(:user) { create(:user, extended_data: { community_ref_me: " 2000 " }) }
    let(:form_object) do
      Class.new do
        attr_reader :user

        def initialize(user)
          @user = user
          @data = {}
        end

        def []=(key, value)
          @data[key] = value
        end

        def [](key)
          @data[key]
        end
      end.new(user)
    end
    let(:builder) do
      instance_double(
        "FormBuilder",
        object: form_object,
        hidden_field: "<input />"
      )
    end

    context "when hide_if_value is enabled and the referenced field has content" do
      let(:options) { { hide_if_value: true } }

      it "renders a hidden field wrapper" do
        with_customizations do
          register_test_customization(:community) do |customization|
            customization.registration_fields { |set| set.add_field(:ref_me, type: :dummy) }
          end
          field.customization_name = :community
          field.configure_form(form_class)

          html = field.form_tag(builder)
          expect(html).to include("hidden")
          expect(html).to include("&lt;input")
        end
      end
    end

    it "handles missing extended_data on the user" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:ref_me, type: :dummy) }
        end
        field.customization_name = :community
        field.configure_form(form_class)

        user_without_data = create(:user, extended_data: nil)
        form_object = Class.new do
          attr_reader :user

          def initialize(user)
            @user = user
            @data = {}
          end

          def []=(_key, _value); end

          def [](_key); end
        end.new(user_without_data)

        builder = instance_double("FormBuilder", object: form_object, hidden_field: "<input />")

        expect { field.form_tag(builder) }.not_to raise_error
      end
    end

    it "restores i18n context after rendering" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:ref_me, type: :dummy) }
        end
        field.customization_name = :community
        field.configure_form(form_class)
        peer = field.send(:peer_field)
        old_context = peer.i18n_context

        field.form_tag(builder)

        expect(peer.i18n_context).to eq(old_context)
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::ExtraFieldRefField do
  around do |example|
    original = Decidim::CustomUserFields.custom_fields.dup
    Decidim::CustomUserFields.custom_fields.clear
    example.run
  ensure
    Decidim::CustomUserFields.custom_fields.replace(original)
  end

  let(:handler_name) { "extended_data" }
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:ref_me, { type: :extra_field_ref }.merge(options), handler_name) }
  let(:field) { definition.field }
  let(:options) { {} }
  let(:form_class) do
    Class.new do
      class << self
        def attribute(*); end

        def validates(*); end
      end
    end
  end
  let(:base_definition) do
    Decidim::CustomUserFields::FieldDefinition.new(:ref_me, { type: :dummy }, handler_name)
  end

  before do
    Decidim::CustomUserFields.custom_fields << base_definition
  end

  describe "#configure_form" do
    it "raises when referenced field is missing" do
      Decidim::CustomUserFields.custom_fields.clear

      expect do
        field.configure_form(form_class)
      end.to raise_error(RuntimeError, /not found/)
    end

    it "builds a reference definition and configures it" do
      field.configure_form(form_class)

      expect(field.reference).to be_a(Decidim::CustomUserFields::FieldDefinition)
      expect(field.reference.name).to eq(:ref_me)
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
    let(:user) { create(:user, extended_data: { ref_me: " 2000 " }) }
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
        field.configure_form(form_class)

        html = field.form_tag(builder)
        expect(html).to include("hidden")
        expect(html).to include("&lt;input")
      end
    end

    it "restores i18n context after rendering" do
      field.configure_form(form_class)
      old_context = field.reference.i18n_context

      field.form_tag(builder)

      expect(field.reference.i18n_context).to eq(old_context)
    end
  end
end

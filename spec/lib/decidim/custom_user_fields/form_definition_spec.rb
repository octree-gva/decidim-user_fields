# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::FormDefinition do
  let(:handler_name) { "extended_data" }

  let(:form_class) do
    Class.new do
      class << self
        attr_reader :attributes, :validations

        def attribute(name, type)
          (@attributes ||= {})[name] = type
        end

        def validates(name, **validations)
          (@validations ||= []) << { name:, validations: }
        end
      end

      def initialize(organization: nil)
        @current_organization = organization
        @data = {}
      end

      attr_reader :current_organization

      def []=(key, value)
        @data[key] = value
      end

      def [](key)
        @data[key]
      end

      def active_custom_field_names
        org = current_organization
        return [] unless org

        RegistrationFields.active_registration_fields(org).map(&:name)
      end
    end
  end

  it "adds configured custom fields at include-time" do
    with_customizations do
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text, required: true) }
      end

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      expect(klass.attributes).to include(default_foo: String)
      expect(klass.validations).not_to be_empty
    end
  end

  it "maps model extended_data into the form for active fields only" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text, required: true) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new({ default_foo: "  bar " })
      form = klass.new(organization:)
      allow(form).to receive(:current_organization).and_return(organization)

      form.map_model(model)

      expect(form[:default_foo]).to eq("bar")
    end
  end

  it "maps extended_data using model.organization when form context is missing" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:flag, type: :boolean, required: true) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data, :organization).new({ default_flag: true }, organization)
      form = klass.new(organization: nil)

      form.map_model(model)

      expect(form[:default_flag]).to be(true)
    end
  end

  it "ignores missing extended_data keys for active fields" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text, required: true) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new(nil)
      form = klass.new(organization:)
      allow(form).to receive(:current_organization).and_return(organization)

      expect { form.map_model(model) }.not_to raise_error
      expect(form[:default_foo]).to be_nil
    end
  end

  it "does not map fields from disabled customizations" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text) }
      end
      register_test_customization(:other) do |customization|
        customization.registration_fields { |set| set.add_field(:bar, type: :text) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new({ default_foo: "yes", other_bar: "no" })
      form = klass.new(organization:)
      allow(form).to receive(:current_organization).and_return(organization)

      form.map_model(model)

      expect(form[:default_foo]).to eq("yes")
      expect(form[:other_bar]).to be_nil
    end
  end

  it "validates required fields from every active customization" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:community) do |customization|
        customization.registration_fields { |set| set.add_field(:city, type: :text, required: true) }
      end
      register_test_customization(:ngos) do |customization|
        customization.registration_fields { |set| set.add_field(:role, type: :text, required: true) }
      end
      Decidim::CustomUserFields::FormDefinition.setup_form_class(Decidim::RegistrationForm)
      enable_customization_for(organization, :community, :ngos)

      base_params = {
        name: "Ada Lovelace",
        email: "ada@example.org",
        password: "decidim123456789",
        tos_agreement: "1",
        newsletter: "0"
      }

      invalid = Decidim::RegistrationForm.from_params(user: base_params).with_context(
        current_organization: organization
      )
      expect(invalid).not_to be_valid
      expect(invalid.errors[:community_city]).to be_present
      expect(invalid.errors[:ngos_role]).to be_present

      valid = Decidim::RegistrationForm.from_params(
        user: base_params.merge(community_city: "Paris", ngos_role: "member")
      ).with_context(current_organization: organization)
      expect(valid).to be_valid
    end
  end
end

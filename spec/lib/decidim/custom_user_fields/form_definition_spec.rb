# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::FormDefinition do
  around do |example|
    original = Decidim::CustomUserFields.custom_fields.dup
    Decidim::CustomUserFields.custom_fields.clear
    example.run
  ensure
    Decidim::CustomUserFields.custom_fields.replace(original)
  end

  let(:handler_name) { "extended_data" }

  let(:form_class) do
    Class.new do
      class << self
        attr_reader :attributes, :validations

        def attribute(name, type)
          (@attributes ||= {})[name] = type
        end

        def validates(name, validations)
          (@validations ||= {})[name] = validations
        end
      end

      def initialize
        @data = {}
      end

      def []=(key, value)
        @data[key] = value
      end

      def [](key)
        @data[key]
      end
    end
  end

  it "adds configured custom fields at include-time" do
    Decidim::CustomUserFields.custom_fields << Decidim::CustomUserFields::FieldDefinition.new(:foo, { type: :dummy }, handler_name)

    klass = Class.new(form_class) do
      include Decidim::CustomUserFields::FormDefinition
    end

    expect(klass.attributes).to include(foo: String)
    expect(klass.validations).to have_key(:foo)
  end

  it "maps model extended_data into the form" do
    Decidim::CustomUserFields.custom_fields << Decidim::CustomUserFields::FieldDefinition.new(:foo, { type: :dummy }, handler_name)

    klass = Class.new(form_class) do
      include Decidim::CustomUserFields::FormDefinition
    end

    model = Struct.new(:extended_data).new({ foo: "  bar " })
    form = klass.new

    form.map_model(model)

    expect(form[:foo]).to eq("bar")
  end
end

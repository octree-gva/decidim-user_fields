# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Verifications::VerificationForm do
  subject do
    klass = Decidim::CustomUserFields::Verifications.create_verification_class(
      klass_name
    )
    fields = [dummy_field]
    klass.decidim_custom_fields = fields
    fields.map do |field|
      field.configure_form(klass)
    end
    klass.new(test_field: data, user:)
  end

  let(:klass_name) { "UserFieldsDummyVerification#{SecureRandom.hex(6)}" }
  let(:dummy_field) do
    Decidim::CustomUserFields::FieldDefinition.new(
      :test_field,
      { type: :dummy },
      "extended_data"
    )
  end
  let(:data) { "2000" }
  let(:user) { create(:user) }

  before do
    allow(dummy_field.field).to receive(:validation_hash).and_return({ presence: true })
  end

  after do
    Decidim::CustomUserFields::Verifications.send(:remove_const, klass_name) if Decidim::CustomUserFields::Verifications.const_defined?(klass_name)
  end

  describe "#sanitize_values" do
    let(:data) { " 2000 " }

    it "sanitizes the values before validation" do
      expect { subject.valid? }.to change(subject, :test_field).from(" 2000 ").to("2000")
    end
  end

  describe "user attribute casting" do
    it "does not materialize the full attributes hash during validation" do
      form = subject
      allow(form).to receive(:attributes).and_call_original

      expect(form).to be_valid
      expect(form).not_to have_received(:attributes)
    end

    it "does not re-instantiate Decidim::User when reading metadata" do
      form = subject
      allow(Decidim::User).to receive(:new).and_call_original

      expect { form.metadata }.not_to raise_error
      expect(Decidim::User).not_to have_received(:new)
    end
  end

  describe "validations" do
    describe "when a field must be in a list of allowed values" do
      before do
        allow(dummy_field.field).to receive(:validation_hash).and_return({ inclusion: { in: %w(2000 2001) } })
      end

      describe "and a valid value is provided" do
        let(:data) { "2000" }

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      describe "and an invalid value is provided" do
        let(:data) { "2002" }

        it "is invalid" do
          expect(subject).to be_invalid
        end
      end

      describe "and a nil value is provided" do
        let(:data) { nil }

        it "is invalid" do
          expect(subject).to be_invalid
        end
      end
    end

    describe "when a field is required" do
      before do
        allow(dummy_field.field).to receive(:validation_hash).and_return({ presence: true })
      end

      describe "and nil value is provided" do
        let(:data) { nil }

        it "is invalid" do
          expect(subject).to be_invalid
        end
      end

      describe "and empty value is provided" do
        let(:data) { "" }

        it "is invalid" do
          expect(subject).to be_invalid
        end
      end

      describe "and valid value is provided" do
        let(:data) { "2000" }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end
  end
end

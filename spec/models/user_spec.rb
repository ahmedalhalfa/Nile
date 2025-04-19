require "rails_helper"

RSpec.describe User, type: :model do
  # Test associations (if any)
  # it { should have_many(:...) }

  # Test secure password
  it { should have_secure_password }

  # Test validations
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value("test@example.com").for(:email) }
    it { should_not allow_value("test@example").for(:email) }
    it { should_not allow_value("test").for(:email) }

    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }

    context "when password is required" do
      it { should validate_presence_of(:password) }
      it { should validate_length_of(:password).is_at_least(6) }
    end

    context "when password is not required (updating without password)" do
      subject { create(:user) } # Create a user first
      before { subject.password = nil } # Simulate update without password
      it { should_not validate_presence_of(:password) }
    end
  end

  # Test factory
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  # Test password reset methods
  describe "password reset methods" do
    let(:user) { create(:user) }

    describe "#generate_password_reset_token" do
      it "generates a unique reset token" do
        expect { user.generate_password_reset_token }.to change { user.reset_password_token }.from(nil)
        expect(user.reset_password_sent_at).to be_within(1.minute).of(Time.now)
      end
    end

    describe "#password_reset_token_valid?" do
      context "when token is recent" do
        before { user.generate_password_reset_token }
        it { expect(user.password_reset_token_valid?).to be true }
      end

      context "when token is old" do
        before do
          user.generate_password_reset_token
          user.update_column(:reset_password_sent_at, 5.hours.ago)
        end
        it { expect(user.password_reset_token_valid?).to be false }
      end

      context "when token is nil" do
        it { expect(user.password_reset_token_valid?).to be false }
      end
    end

    describe "#reset_password" do
      before { user.generate_password_reset_token }
      let(:new_password) { "newpassword123" }

      it "updates the password" do
        expect { user.reset_password(new_password) }.to change { user.password_digest }
      end

      it "clears the reset token and timestamp" do
        user.reset_password(new_password)
        expect(user.reset_password_token).to be_nil
        expect(user.reset_password_sent_at).to be_nil
      end

      it "returns true on success" do
        expect(user.reset_password(new_password)).to be true
      end

      it "returns false on failure (e.g., validation error)" do
        expect(user.reset_password("short")).to be false
      end
    end
  end
end

require "rails_helper"

RSpec.describe Book, type: :model do
  # Test associations
  it { should belong_to(:author) }

  # Test validations
  describe "validations" do
    subject { build(:book) } # Use factory to build a valid object first

    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(2) }
  end

  # Test factory
  it "has a valid factory" do
    expect(build(:book)).to be_valid
  end
end

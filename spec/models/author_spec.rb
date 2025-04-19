require "rails_helper"

RSpec.describe Author, type: :model do
  # Test associations
  it { should have_many(:books) }

  # Test validations (if any)
  # describe 'validations' do
  #   it { should validate_presence_of(:first_name) }
  #   it { should validate_presence_of(:last_name) }
  # end

  # Test factory
  it "has a valid factory" do
    expect(build(:author)).to be_valid
  end
end

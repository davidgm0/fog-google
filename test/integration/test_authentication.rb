require "helpers/integration_test_helper"

# TODO: this is a port over from legacy tests.  It shouldn't be scoped under Google, but under Google::Shared.
class TestAuthentication < FogIntegrationTest
  def setup
    @google_json_key_location = Fog.credentials[:google_json_key_location]
    @google_json_key_string = File.open(File.expand_path(@google_json_key_location), "rb", &:read)
  end

  def test_authenticates_with_json_key_location
    c = Fog::Google::Compute.new(:google_key_location => nil,
                                 :google_key_string => nil,
                                 :google_json_key_location => @google_json_key_location,
                                 :google_json_key_string => nil)
    assert_kind_of(Fog::Google::Compute::Real, c)
  end

  def test_authenticates_with_json_key_string
    c = Fog::Google::Compute.new(:google_key_location => nil,
                                 :google_key_string => nil,
                                 :google_json_key_location => nil,
                                 :google_json_key_string => @google_json_key_string)
    assert_kind_of(Fog::Google::Compute::Real, c)
  end

  def test_raises_argument_error_when_google_project_is_missing
    assert_raises(ArgumentError) { Fog::Google::Compute.new(:google_project => nil) }
  end

  def test_raises_argument_error_when_google_keys_are_given
    assert_raises(ArgumentError) do
      Fog::Google::Compute.new(:google_key_location => nil,
                               :google_key_string => nil,
                               :google_json_key_location => nil,
                               :google_json_key_string => nil)
    end
  end
end

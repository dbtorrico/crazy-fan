ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Helper para montar um AuthHash do Google no modo test do OmniAuth
    def mock_google_auth(uid: "test_uid_999", email: "teste@gmail.com", name: "Teste User")
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: uid,
        info: {
          email: email,
          name: name,
          first_name: name.split.first,
          image: "https://example.com/avatar.jpg"
        }
      )
    end

    def clear_google_mock
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end
  end
end

require "test_helper"
require Rails.root.join("lib/mp_gateway")

class MpGatewayTest < ActiveSupport::TestCase
  # SDK falso para injeção — não chama a API real.
  class FakeSdk
    attr_reader :last_post_path, :last_post_data, :last_notification_id

    def initialize(post_response: {}, notification_response: {})
      @post_response         = post_response
      @notification_response = notification_response
    end

    def post(path, data)
      @last_post_path = path
      @last_post_data = data
      @post_response
    end

    def notification(id)
      @last_notification_id = id
      @notification_response
    end
  end

  def pix_success_response
    {
      "id"                      => 123456,
      "status"                  => "pending",
      "point_of_interaction"    => {
        "transaction_data" => {
          "qr_code"        => "00020126...",
          "qr_code_base64" => "iVBORw0K..."
        }
      }
    }
  end

  # --- create_pix_payment ---

  test "create_pix_payment retorna ok:true com id e qr_code em sucesso" do
    sdk     = FakeSdk.new(post_response: pix_success_response)
    gateway = MpGateway.new(sdk: sdk)
    user    = users(:joao)

    result = gateway.create_pix_payment(user: user, external_reference: "user_1_1000")

    assert result[:ok]
    assert_equal 123456, result[:id]
    assert_equal "00020126...", result[:qr_code]
    assert_equal "iVBORw0K...", result[:qr_code_base64]
  end

  test "create_pix_payment envia payment_method_id pix e valor correto" do
    sdk     = FakeSdk.new(post_response: pix_success_response)
    gateway = MpGateway.new(sdk: sdk)

    gateway.create_pix_payment(user: users(:joao), external_reference: "user_1_1000")

    assert_equal "/v1/payments",  sdk.last_post_path
    assert_equal "pix",           sdk.last_post_data[:payment_method_id]
    assert_equal 5.0,             sdk.last_post_data[:transaction_amount]
    assert_equal "user_1_1000",   sdk.last_post_data[:external_reference]
  end

  test "create_pix_payment retorna ok:false quando API retorna erro" do
    error_response = { "error" => "bad_request", "message" => "Invalid payer email" }
    sdk     = FakeSdk.new(post_response: error_response)
    gateway = MpGateway.new(sdk: sdk)

    result = gateway.create_pix_payment(user: users(:joao), external_reference: "user_1_1000")

    assert_not result[:ok]
    assert_equal "Invalid payer email", result[:error]
  end

  test "create_pix_payment retorna ok:false em exceção" do
    sdk = FakeSdk.new
    def sdk.post(*, **) = raise "connection refused"
    gateway = MpGateway.new(sdk: sdk)

    result = gateway.create_pix_payment(user: users(:joao), external_reference: "user_1_1000")

    assert_not result[:ok]
    assert_includes result[:error], "connection refused"
  end

  # --- get_payment ---

  test "get_payment retorna o hash do pagamento" do
    payment = { "id" => 123456, "status" => "approved", "external_reference" => "user_1_1000" }
    sdk     = FakeSdk.new(notification_response: payment)
    gateway = MpGateway.new(sdk: sdk)

    result = gateway.get_payment(123456)

    assert_equal "approved",    result["status"]
    assert_equal "user_1_1000", result["external_reference"]
    assert_equal "123456",      sdk.last_notification_id
  end

  test "get_payment retorna nil em exceção" do
    sdk = FakeSdk.new
    def sdk.notification(*) = raise "timeout"
    gateway = MpGateway.new(sdk: sdk)

    assert_nil gateway.get_payment(999)
  end
end

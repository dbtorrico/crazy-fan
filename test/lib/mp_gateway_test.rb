require "test_helper"
require Rails.root.join("lib/mp_gateway")

class MpGatewayTest < ActiveSupport::TestCase
  # HTTP client falso para injeção — não chama a API real.
  class FakeHttp
    attr_reader :last_post_path, :last_post_data, :last_get_path

    def initialize(post_response: {}, get_response: {})
      @post_response = post_response
      @get_response  = get_response
    end

    def post(path, data)
      @last_post_path = path
      @last_post_data = data
      @post_response
    end

    def get(path)
      @last_get_path = path
      @get_response
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
    http    = FakeHttp.new(post_response: pix_success_response)
    gateway = MpGateway.new(http: http)
    user    = users(:joao)

    result = gateway.create_pix_payment(user: user, external_reference: "user_1_1000")

    assert result[:ok]
    assert_equal 123456, result[:id]
    assert_equal "00020126...", result[:qr_code]
    assert_equal "iVBORw0K...", result[:qr_code_base64]
  end

  test "create_pix_payment envia payment_method_id pix e valor correto" do
    http    = FakeHttp.new(post_response: pix_success_response)
    gateway = MpGateway.new(http: http)

    gateway.create_pix_payment(user: users(:joao), external_reference: "user_1_1000")

    assert_equal "/v1/payments",  http.last_post_path
    assert_equal "pix",           http.last_post_data[:payment_method_id]
    assert_equal 5.0,             http.last_post_data[:transaction_amount]
    assert_equal "user_1_1000",   http.last_post_data[:external_reference]
  end

  test "create_pix_payment retorna ok:false quando API retorna erro" do
    error_response = { "error" => "bad_request", "message" => "Invalid payer email" }
    http    = FakeHttp.new(post_response: error_response)
    gateway = MpGateway.new(http: http)

    result = gateway.create_pix_payment(user: users(:joao), external_reference: "user_1_1000")

    assert_not result[:ok]
    assert_equal "Invalid payer email", result[:error]
  end

  test "create_pix_payment retorna ok:false em exceção" do
    http = FakeHttp.new
    def http.post(*, **) = raise "connection refused"
    gateway = MpGateway.new(http: http)

    result = gateway.create_pix_payment(user: users(:joao), external_reference: "user_1_1000")

    assert_not result[:ok]
    assert_includes result[:error], "connection refused"
  end

  # --- get_payment ---

  test "get_payment retorna o hash do pagamento" do
    payment = { "id" => 123456, "status" => "approved", "external_reference" => "user_1_1000" }
    http    = FakeHttp.new(get_response: payment)
    gateway = MpGateway.new(http: http)

    result = gateway.get_payment(123456)

    assert_equal "approved",              result["status"]
    assert_equal "user_1_1000",           result["external_reference"]
    assert_equal "/v1/payments/123456",   http.last_get_path
  end

  test "get_payment retorna nil em exceção" do
    http = FakeHttp.new
    def http.get(*) = raise "timeout"
    gateway = MpGateway.new(http: http)

    assert_nil gateway.get_payment(999)
  end
end

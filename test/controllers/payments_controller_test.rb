require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  def sign_in_as(user)
    mock_google_auth(uid: user.uid, email: user.email, name: "Teste")
    get "/users/auth/google_oauth2/callback"
    clear_google_mock
  end

  class FakeHttp
    def initialize(post_response: {}, get_response: {})
      @post_response = post_response
      @get_response  = get_response
    end

    def post(*, **) = @post_response
    def get(*) = @get_response
  end

  def fake_gateway(post_response: {}, get_response: {})
    http = FakeHttp.new(post_response: post_response, get_response: get_response)
    MpGateway.new(http: http)
  end

  # --- POST /payments/create ---

  test "create redireciona para root com alerta quando MP retorna erro" do
    sign_in_as(users(:joao))
    gw = fake_gateway(post_response: { "error" => "bad_request", "message" => "erro" })
    MpGateway.stub(:new, gw) do
      post create_payments_path
    end
    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end

  test "create renderiza show com QR code em sucesso" do
    sign_in_as(users(:joao))
    pix_response = {
      "id"                   => 999,
      "point_of_interaction" => {
        "transaction_data" => { "qr_code" => "00020126", "qr_code_base64" => "abc123" }
      }
    }
    gw = fake_gateway(post_response: pix_response)
    MpGateway.stub(:new, gw) do
      post create_payments_path
    end
    assert_response :success
    assert_match "00020126", response.body
  end

  test "create exige login — convidado é redirecionado" do
    post create_payments_path
    assert_response :redirect
  end

  # --- POST /payments/webhook ---

  test "webhook ignora notificações que não são de pagamento" do
    user = users(:joao)
    post payments_webhook_path, params: { type: "merchant_order", data: { id: "1" } }
    assert_response :ok
    assert_nil user.reload.premium_until
  end

  test "webhook ativa premium quando pagamento é aprovado" do
    user     = users(:joao)
    approved = { "status" => "approved", "external_reference" => "user_#{user.id}_1000" }
    gw       = fake_gateway(get_response: approved)
    MpGateway.stub(:new, gw) do
      post payments_webhook_path, params: { type: "payment", data: { id: "123" } }
    end
    assert_response :ok
    assert user.reload.premium?, "premium_until deve estar no futuro"
  end

  test "webhook não ativa premium quando pagamento está pendente" do
    user    = users(:joao)
    pending = { "status" => "pending", "external_reference" => "user_#{user.id}_1000" }
    gw      = fake_gateway(get_response: pending)
    MpGateway.stub(:new, gw) do
      post payments_webhook_path, params: { type: "payment", data: { id: "123" } }
    end
    assert_response :ok
    assert_nil user.reload.premium_until
  end

  test "webhook não ativa premium quando get_payment retorna nil" do
    user = users(:joao)
    gw   = fake_gateway(get_response: nil)
    MpGateway.stub(:new, gw) do
      post payments_webhook_path, params: { type: "payment", data: { id: "999" } }
    end
    assert_response :ok
    assert_nil user.reload.premium_until
  end

  test "webhook não ativa premium para external_reference inválido" do
    approved = { "status" => "approved", "external_reference" => "invalid_ref" }
    gw       = fake_gateway(get_response: approved)
    MpGateway.stub(:new, gw) do
      post payments_webhook_path, params: { type: "payment", data: { id: "123" } }
    end
    assert_response :ok
    assert_nil users(:joao).reload.premium_until
  end

  test "webhook não ativa premium para user_id inexistente" do
    approved = { "status" => "approved", "external_reference" => "user_99999_1000" }
    gw       = fake_gateway(get_response: approved)
    MpGateway.stub(:new, gw) do
      post payments_webhook_path, params: { type: "payment", data: { id: "123" } }
    end
    assert_response :ok
  end

  test "webhook é acessível sem autenticação" do
    post payments_webhook_path, params: { type: "merchant_order", data: { id: "1" } }
    assert_response :ok
  end
end

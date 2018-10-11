defmodule Cassette.AuthenticationTest do
  use ExUnit.Case, async: true
  alias Cassette.Authentication
  alias Cassette.User

  setup context do
    {:ok, content} = File.read("test/fixtures/cas/#{context[:file_name]}")
    {:ok, file_content: content}
  end

  @tag file_name: "failure.xml"
  test "handle_response/1 fails when authentication fail",
       %{file_content: file_content} do
    assert {:error, "INVALID_SERVICE: ticket 'X' is invalid"} =
             Authentication.handle_response(file_content)
  end

  @tag file_name: "failure_no_special_chars.xml"
  test "handle_response/1 fails when authentication fail with no special chars" <> " in body", %{
    file_content: file_content
  } do
    assert {:error, "INVALID_SERVICE: ticket is invalid"} =
             Authentication.handle_response(file_content)
  end

  @tag file_name: "success.xml"
  test "handle_response/1 returns {:ok, User} with the user type",
       %{file_content: file_content} do
    assert {:ok, %User{login: "example", type: "employee"}} =
             Authentication.handle_response(file_content)
  end

  @tag file_name: "success_multiple_authorities.xml"
  test "handle_response/1 handles authorities", %{file_content: file_content} do
    {:ok, user} = Authentication.handle_response(file_content)
    expected = Enum.into(["ACME_ADMIN", "ACME_SOMETHING", "ACME_ELSE"], %MapSet{})

    assert MapSet.equal?(expected, user.authorities)
  end

  @tag file_name: "systems_success.xml"
  test "handle_response/1 returns {:ok, User} with empty user type",
       %{file_content: file_content} do
    assert {:ok, %User{login: "example"}} = Authentication.handle_response(file_content)
  end

  @tag file_name: "success.xml"
  test "handle_response/1 parses user extra attributes",
       %{file_content: file_content} do
    assert {:ok, %User{attributes: attributes}} = Authentication.handle_response(file_content)

    assert %{"cn" => "John Smith"} == attributes
  end

  @tag file_name: "invalid_response.xml"
  test "handle_response/1 returns error for an invalid response",
       %{file_content: file_content} do
    assert {:error, reason} = Authentication.handle_response(file_content)
    assert reason =~ ~r/invalid response/
  end
end

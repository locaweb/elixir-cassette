defmodule Cassette.Authentication do
  @moduledoc """
  ST validation functions
  """

  alias Cassette.User

  import Cassette.Version, only: [version: 2]

  require Cassette.Version

  @doc """
  Extracts the authenticated user from validation response

  Returns a tuple with:

  * `{:ok, Cassette.User.t}` on success
  * `{:error, String.t}` on error where the string is the failure reason
    returned by the cas server
  """
  @spec handle_response(String.t()) :: {:ok, User.t()} | {:error, String.t()}
  def handle_response(body) do
    import SweetXml

    xml = SweetXml.parse(body)

    failure = {
      to_string(SweetXml.xpath(xml, ~x"//cas:authenticationFailure/text()"o)),
      to_string(SweetXml.xpath(xml, ~x"//cas:authenticationFailure/@code"o))
    }

    case failure do
      {"", ""} ->
        extract_user(xml)

      {reason, code} when is_binary(reason) ->
        message =
          code <> ": " <> version(">= 1.3.0", do: &String.trim/1, else: &String.strip/1).(reason)

        {:error, message}
    end
  end

  @spec extract_user(any) :: {:ok, User.t()} | {:error}
  defp extract_user(xml) do
    import SweetXml

    login = xpath(xml, ~x"//cas:authenticationSuccess/cas:user/text()"os)

    if login && login != "" do
      attributes_path = "//cas:authenticationSuccess/cas:attributes"
      mapping = [name: ~x"local-name()"s, value: ~x"text()"s]

      all_attributes =
        xml
        |> xpath(~x"#{attributes_path}/*"l, mapping)
        |> Enum.into(%{}, fn attr -> {attr.name, attr.value} end)

      {special, attributes} = Map.split(all_attributes, ["authorities", "type"])

      parse_authorities = fn str ->
        version ">= 1.5.0" do
          str
          |> String.trim_leading("[")
          |> String.trim_trailing("]")
          |> String.split(~r(,\s*))
        else
          str
          |> String.lstrip(?[)
          |> String.strip(?])
          |> String.split(~r(,\s*))
        end
      end

      authorities =
        special
        |> Map.get("authorities", "")
        |> parse_authorities.()

      {:ok, User.new(login, special["type"] || "", authorities, attributes)}
    else
      {:error, "invalid response from cas server"}
    end
  end
end

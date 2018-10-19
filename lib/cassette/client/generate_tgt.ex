defmodule Cassette.Client.GenerateTgt do
  @moduledoc """
  Generates CAS Ticket Granting Tickets
  """

  use HTTPoison.Base

  alias Cassette.Client
  alias Cassette.Config
  alias HTTPoison.Response

  @type result ::
          {:error, :bad_credentials}
          | {:ok, String.t()}
          | {:fail, pos_integer()}
          | {:fail, :unknown}

  @spec process_headers([{String.t(), String.t()}]) :: %{String.t() => String.t()}
  def process_headers(headers) do
    Enum.into(headers, %{}, fn {k, v} ->
      {String.downcase(k), v}
    end)
  end

  @doc """
  Do request to cas service to get a ticket granting tickets from user
  """
  @spec perform(Config.t()) :: result
  def perform(config = %Config{username: username, password: password, base_url: base_url}) do
    form_data = {:form, [username: username, password: password]}
    url = "#{base_url}/v1/tickets"
    headers = %{accept: "*/*"}
    options = Client.options(config)

    case post(url, form_data, headers, options) do
      {:ok, %Response{status_code: 400}} ->
        {:error, :bad_credentials}

      {:ok, %Response{status_code: 201, headers: %{"location" => loc}}} ->
        {:ok, extract_tgt(base_url, loc)}

      {:ok, %Response{status_code: status_code}} ->
        {:fail, status_code}

      _ ->
        {:fail, :unknown}
    end
  end

  @spec extract_tgt(String.t(), String.t()) :: String.t()
  defp extract_tgt(base_url, location) when is_binary(location) do
    String.replace_leading(location, "#{base_url}/v1/tickets/", "")
  end
end

defmodule Cassette.Client do
  @moduledoc """
  Cas Client wrapper functions

  Generates Ticket Granting Tickets and Service Tickets
  Also provides helpers for the default options for the client
  """

  alias Cassette.Client.GenerateSt
  alias Cassette.Client.GenerateTgt
  alias Cassette.Config

  @doc """
  Generates a ticket granting ticket given the config

  Checkout `Cassette.Client.GenerateTgt.perform/1` for details on responses
  """
  @spec tgt(Config.t()) :: GenerateTgt.response()
  def tgt(config) do
    GenerateTgt.perform(config)
  end

  @doc """
  Generates a service ticket ticket given the config, a valid tgt and the target
  service

  Checkout `Cassette.Client.GenerateSt.perform/3` for details on responses
  """
  @spec st(Config.t(), String.t(), String.t()) :: GenerateSt.response()
  def st(config, current_tgt, service) do
    GenerateSt.perform(config, current_tgt, service)
  end

  @doc false
  @spec options(Config.t()) :: []
  def options(config) do
    if config.insecure do
      [hackney: [:insecure]]
    else
      []
    end
  end
end

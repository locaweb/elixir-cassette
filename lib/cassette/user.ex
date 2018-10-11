defmodule Cassette.User do
  @moduledoc """
  This is the struct that represents the user returned by a Validation request
  """

  alias Cassette.Config
  alias Cassette.User

  defstruct login: "", type: "", attributes: %{}, authorities: MapSet.new([])

  @type t :: %__MODULE__{login: String.t(), attributes: map()}

  @doc """
  Initializes a `Cassette.User` struct, mapping the list of authorities to it's
  internal representation
  """
  @spec new(String.t(), [String.t()]) :: User.t()
  def new(login, authorities) do
    new(login, "", authorities)
  end

  @doc """
  Initializes a `Cassette.User` struct, with a `type` attribute and mapping the
  list of authorities to it's internal representation
  """
  @spec new(String.t(), String.t(), [String.t()]) :: User.t()
  def new(login, type, authorities) do
    %User{login: login, type: String.downcase(type), authorities: MapSet.new(authorities)}
  end

  @doc """
  Initializes a `Cassette.User` struct, with a `type` attribute, mapping the
  list of authorities, and any extra attribute returned by the server
  """
  @spec new(String.t(), String.t(), [String.t()], map()) :: User.t()
  def new(login, type, authorities, attributes) do
    %User{
      login: login,
      type: String.downcase(type),
      attributes: attributes,
      authorities: MapSet.new(authorities)
    }
  end

  @doc """
  Tests if the user has the given `role` respecting the `base_authority` set in
  the default configuration

  If your `base_authority` is `ACME` and the user has the `ACME_ADMIN`
  authority, then the following is true:

  ```elixir
  iex> Cassette.User.role?(some_user, "ADMIN")
  true
  iex> Cassette.User.has_role?(some_user, "ADMIN")
  true
  ```

  This function returns false when user is not a Cassette.User.t

  """
  @spec role?(User.t() | any, String.t() | any) :: boolean
  def role?(user = %User{}, role) do
    User.role?(user, Config.default(), role)
  end

  def role?(_, _), do: false

  defdelegate has_role?(user, role), to: __MODULE__, as: :role?

  @doc """
  Tests if the user has the given `role` using the `base_authority` set in the
  default configuration

  If you are using custom a `Cassette.Support` server you can use this function
  to respect it's `base_authority`

  This function returns false when user is not a Cassette.User.t

  """
  @spec role?(User.t() | any, Config.t() | any, String.t() | any) :: boolean
  def role?(user = %User{}, %Config{base_authority: base}, role) do
    User.raw_role?(user, to_raw_role(base, role))
  end

  def role?(_, _, _), do: false

  defdelegate has_role?(user, config, role), to: __MODULE__, as: :role?

  @doc """
  Tests if the user has the given `role`.
  This function does not alter the role when checking against the list of
  authorities.

  If your user has the `ACME_ADMIN` authority the following is true:

  ```elixir
  iex> Cassette.User.raw_role?(some_user, "ACME_ADMIN")
  true
  iex> Cassette.User.has_raw_role?(some_user, "ACME_ADMIN")
  true
  ```

  This function returns false when user is not a Cassette.User.t

  """
  @spec raw_role?(User.t() | any, String.t() | any) :: boolean
  def raw_role?(%User{authorities: authorities}, raw_role) do
    MapSet.member?(authorities, String.upcase(to_string(raw_role)))
  end

  def raw_role?(_, _), do: false

  defdelegate has_raw_role?(user, role), to: __MODULE__, as: :raw_role?

  @spec to_raw_role(String.t() | nil, String.t()) :: String.t()
  defp to_raw_role(base, role) do
    [base, role]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("_")
  end
end

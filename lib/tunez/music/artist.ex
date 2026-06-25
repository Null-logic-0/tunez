defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :artist

    filterable_fields [
      :album_count,
      :cover_image_url,
      :inserted_at,
      :latest_album_year_released,
      :updated_at
    ]
  end

  json_api do
    type "artist"
    includes [:albums]
    derive_filter? false
  end

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  resource do
    description "A person or group of people that makes and releases music"
  end

  actions do
    read :search do
      argument :query, :ci_string do
        constraints allow_empty?: true
        default ""
        description "The search query to filter artists by name"
      end

      filter expr(contains(name, ^arg(:query)))
      pagination offset?: true, default_limit: 10

      # prepare build(load: [:album_count, :latest_album_year_released, :cover_image_url])
    end

    create :create do
      accept [:name, :biography]
    end

    update :update do
      require_atomic? false
      accept [:name, :biography]

      change Tunez.Music.Changes.UpdatePreviousNames, where: [changing(:name)]
    end

    # destroy :destroy do
    # end
    defaults [:read, :destroy]
  end

  policies do
    policy action(:create) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:update) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :editor)
    end

    policy action(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action_type(:update) do
      authorize_if actor_present()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:force_update) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end

  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    change relate_actor(:updated_by, allow_nil?: true)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :previous_names, {:array, :string} do
      default []
      public? true
    end

    attribute :biography, :string do
      public? true
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
      public? true
    end

    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User
  end

  # calculations do
  #   calculate :years_ago, :integer, expr(2026 - year_released)

  #   calculate :string_years_ago,
  #             :string,
  #             expr("wow,this was released " <> years_ago <> " years ago!")

  #   calculate :album_count, :integer, expr(count(albums))
  #   calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))

  #   calculate :cover_image_url, :string, expr(first(albums, field: :cover_image_url))
  # end

  aggregates do
    count :album_count, :albums do
      public? true
    end

    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url do
      public? true
    end
  end
end

defmodule Tunez.Music do
  use Ash.Domain, otp_app: :tunez, extensions: [AshPhoenix]

  forms do
    form :create_album, args: [:artist_id]
  end

  resources do
    resource Tunez.Music.Artist do
      define :read_artists, action: :read

      define :search_artists,
        action: :search,
        args: [:query],
        default_options: [
          load: [:album_count, :latest_album_year_released, :cover_image_url]
        ]

      define :get_artist_by_id, action: :read, get_by: :id
      define :create_artist, action: :create
      define :update_artist, action: :update
      define :destroy_artist, action: :destroy
    end

    resource Tunez.Music.Album do
      define :get_album_by_id, action: :read, get_by: :id
      define :create_album, action: :create
      define :update_album, action: :update
      define :destroy_album, action: :destroy
    end
  end
end

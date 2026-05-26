if not set -q BRAVE_SEARCH_API_KEY
    set -l brave_search_api_key_file "$XDG_CONFIG_HOME/opnix/secrets/brave-search-api-key"
    if test -r "$brave_search_api_key_file"
        set -gx BRAVE_SEARCH_API_KEY (string collect <"$brave_search_api_key_file")
    end
end

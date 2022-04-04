# `gotrue-swift`

Swift client for the [GoTrue](https://github.com/supabase/gotrue) API.

## Using

The usage should be the same as gotrue-js except:

Oauth2:

- `signIn` with oauth2 provider only return provider url. Users have to launch that url to continue the auth flow.
- After receiving callback uri from oauth2 provider, use `getSessionFromUrl` to parse session data.

Persist/restore session:

- Default persist storage provided using UserDefaults.
- 
## Contributing

- Fork the repo on [GitHub](https://github.com/supabase/gotrue-swift)
- Clone the project to your own machine
- Commit changes to your own branch
- Push your work back up to your fork
- Submit a Pull request so that we can review your changes and merge

## License

This repo is licensed under MIT.

## Credits

- https://github.com/supabase/gotrue-js - ported from supabase/gotrue-js fork
- https://github.com/netlify/gotrue-js - original library

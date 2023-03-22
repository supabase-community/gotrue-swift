# `gotrue-swift`

Swift client for the [GoTrue](https://github.com/supabase/gotrue) API.

## Using

The usage should be the same as gotrue-js except:

Oauth2:

- `signIn` with OAuth2 provider only return provider url. Users have to launch that url to continue the auth flow.
- After receiving callback uri from OAuth2 provider, use `session(from url: URL)` to parse session data.

## Running Examples

For running the examples project you'll have to provide your own Supabase project.

```sh
$ cp Examples/Shared/Sources/_Secrets.swift Examples/Shared/Sources/Secrets.swift
$ Examples/Shared/Sources/Secrets.swift # Or use you favorite editor
```

Replace `{PROJECT_ID}` and `{ANON_KEY}` with real values for your project on the Supabase portal.

Check [Examples](/Examples) for example usages.

## Contributing

- Fork the repo on [GitHub](https://github.com/supabase-community/gotrue-swift)
- Clone the project to your own machine
- Commit changes to your own branch
- Push your work back up to your fork
- Submit a Pull request so that we can review your changes and merge

## License

This repo is licensed under MIT.

## Credits

- https://github.com/supabase/gotrue-js - ported from supabase/gotrue-js fork
- https://github.com/netlify/gotrue-js - original library

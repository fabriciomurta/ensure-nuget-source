# Ensure NuGet Source

This action ensures NuGet is set up to the public NuGet sources URL or a specified url/path passed in.

By default it uses `nuget.org` as the source name and `https://api.nuget.org/v3/index.json` as the source URL/path.

# Usage

<!-- start usage -->
```yaml
- uses: fabriciomurta/ensure-nuget-source@v1
  with:
    # The name that should be used when adding the source if not present.
    # The action will check if the name exists; if it does, then its url/path
    # is updated to point to the desired URL value.
    name: 'nuget.org'

    # The url that should be present and enabled in the source list. If not
    # present, will be added. If present and disabled, enabled.
    url: 'https://api.nuget.org/v3/index.json'
```
<!-- end usage -->

# License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
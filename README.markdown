# [Rattletrap][]

[![Version badge][]][version]
[![Build badge][]][build]
[![Docker badge][]][docker]

Rattletrap parses and generates [Rocket League][] replays. Parsing replays can
be used to analyze data in order to collect high-level statistics like players
and points, or low-level details like positions and cameras. Generating replays
can be used to modify replays in order to force everyone into the same car or
change the map a game was played on.

Rattletrap supports every version of Rocket League up to [1.95][], which was
released on 2021-04-14. If a replay can be played by the Rocket League client,
it can be parsed by Rattletrap. (If not, that's a bug. Please report it!)

Rattletrap is a command-line application. You should only use it if you're
comfortable running things in terminals or command prompts. Otherwise consider
using another tool like [Ball Chasing][]. Rattletrap is written in [Haskell][].
If you'd like to use a program written in a different language, consider
@jjbott's [C# parser][] or @nickbabcock's [Rust parser][].

## Install

Get Rattletrap by downloading [the latest release][] for your platform.

Rattletrap is also available as [a Docker image][docker].

To build Rattletrap from source, install [Stack][]. Then run
`stack --resolver lts-14.25 install rattletrap`.

## Replays

Rocket League saves your replays in a folder that depends on your operating
system.

- Windows:
  - `%UserProfile%/Documents/My Games/Rocket League/TAGame/Demos`
  - For example: `C:/Users/Taylor/Documents/My Games/Rocket League/TAGame/Demos`
- macOS:
  - `$HOME/Library/Application Support/Rocket League/TAGame/Demos`
  - For example: `/Users/taylor/Library/Application Support/Rocket League/TAGame/Demos`
- Linux:
  - `$HOME/.local/share/Rocket League/TAGame/Demos`
  - For example: `/home/taylor/.local/share/Rocket League/TAGame/Demos`

## Interface

Rattletrap is a command line application.

``` sh
$ rattletrap --help
```

```
rattletrap version 10.0.0
  -c           --compact         minify JSON output
  -f           --fast            only encode or decode the header
  -h           --help            show the help
  -i FILE|URL  --input=FILE|URL  input file or URL
  -m MODE      --mode=MODE       decode or encode
  -o FILE      --output=FILE     output file
               --schema          output the schema
               --skip-crc        skip the CRC
  -v           --version         show the version
```

By default Rattletrap will try to determine the appropriate mode (either decode
or encode) based on the file extensions of the input or output. You can
override this behavior by passing `--mode` (or `-m`) with either `decode` or
`encode`.

Input extension | Output extension | Mode
---             | ---              | ---
`.replay`       | anything         | `decode` (parse)
`.json`         | anything         | `encode` (generate)
anything        | `.replay`        | `encode` (generate)
anything        | `.json`          | `decode` (parse)
anything        | anything         | `decode` (parse)

## Parse

Rattletrap can parse (decode) Rocket League replays and output them as JSON.

``` sh
$ rattletrap --input http://example.com/input.replay --output output.json
# or
$ rattletrap -i input.replay -o output.json
# or
$ rattletrap < input.replay > output.json
```

The input argument can either be a local path or a URL.

By default the JSON is pretty-printed. To minify the JSON, pass `--compact` (or
`-c`) to Rattletrap. Even when the JSON is minified, it's extremely large. The
output can be up to 100 times larger than the input. For example, a 1.5 MB
replay turns into 31 MB of minified JSON or 159 MB of pretty-printed JSON.

## Generate

Rattletrap can also generate (encode) Rocket League replays from JSON files.

``` sh
$ rattletrap --input http://example.com/input.json --output output.replay
# or
$ rattletrap -i input.json -o output.replay
# or
$ rattletrap --mode encode < input.json > output.replay
```

The input argument can either be a local path or a URL.

If the JSON was generated by Rattletrap, the output replay will be bit-for-bit
identical to the input replay.

## Modify

By inserting another program between parsing and generating, Rattletrap can be
used to modify replays.

``` sh
$ rattletrap -i input.replay |
  modify-replay-json |
  rattletrap -o output.replay
```

[Rattletrap]: https://github.com/tfausak/rattletrap
[Version badge]: https://img.shields.io/hackage/v/rattletrap.svg?logo=haskell
[version]: https://hackage.haskell.org/package/rattletrap
[Build badge]: https://github.com/tfausak/rattletrap/workflows/ci/badge.svg
[build]: https://github.com/tfausak/rattletrap/actions
[Docker badge]: https://img.shields.io/docker/v/taylorfausak/rattletrap?label=docker&logo=docker&logoColor=white
[docker]: https://hub.docker.com/r/taylorfausak/rattletrap
[Rocket League]: https://www.rocketleague.com
[1.95]: https://www.rocketleague.com/news/patch-notes-v1-95/
[Ball Chasing]: https://ballchasing.com
[Haskell]: https://www.haskell.org
[C# parser]: https://github.com/jjbott/RocketLeagueReplayParser
[Rust parser]: https://github.com/nickbabcock/rrrocket
[the latest release]: https://github.com/tfausak/rattletrap/releases/latest
[Stack]: https://docs.haskellstack.org/en/stable/README/

# Cake Demo Apps

## Running local demo apps

The demo apps come with a `docker-compose.yaml` file which contains a
database setup. You will need to install or have installed _Git_, _Erlang_,
_Gleam_, and _Docker_ however, thus:

### Installing prerequisites

If not already installed, install:

1. Install [Git](https://github.com/git-guides/install-git).
2. Install _Erlang_, _Rebar3_, and _Gleam_, see
   [Installing](https://gleam.run/getting-started/installing/) chapter on the
	 Gleam website for instructions.
3. Install [Docker Desktop](https://docs.docker.com/desktop/) or
   [Docker Engine](https://docs.docker.com/engine/install/).

### Obtaining a copy of Cake

Open a terminal of your choice to clone _Cake_:

```shell
git clone https://github.com/inoas/gleam-cake.git
cd gleam-cake
```

### Starting the docker compose setup for demo apps

Open a terminal of your choice and within the `gleam-cake` directory cloned
above:

```shell
cd docs
cd demo-apps
cd docker-setup-for-demos
bin/docker/attached
```

## Start the demo app

```shell
cd 01_demo_select_and_decode # ...or any other demo app!
gleam run
```

### Available demos

- [`SELECT` and decode into Cats](demo-apps/01_demo_select_and_decode/README.md)
- [`UNION` and decode into Beings](demo-apps/02_demo_union_and_decode/README.md)

---

If you want to edit and change the demos to try and explore _Cake_ you may
chose whatever code editor you prefer but _Cake_ recommends chosing either
[Zed](https://zed.dev/) or [Visual Studio Code](https://code.visualstudio.com/)
— both feature _Gleam_ plugins and thus _Gleam_ specific _Language Server
Protocol_ support — especially if you are new to _Gleam_.

To just explore a single demo app, open just that app in your editor, so that
the _Gleam_ LSP can pick up that demo projects's `gleam.toml` file.

For example if you have `Zed` or `Visual Studio Code` installed you may run one
of these form the `gleam-cake` directory cloned above:

- `code docs/demo-apps/01_demo_select_and_decode`
- `zed docs/demo-apps/01_demo_select_and_decode`

## TODOs

- Maybe move Erlang, Rebar and Gleam requirement into docker compose.

# Cake Demo Apps

## Running local example apps

The example apps come with a `docker-compose.yaml` file which contains a database setup. You will need to install or have installed _Git_, _Erlang_, _Gleam_, and _Docker_ however, thus:

### Installing prerequisites

If not already installed, install:

1. Install [Git](https://github.com/git-guides/install-git).
2. Install Erlang, Rebar3, and Gleam, see [Installing](https://gleam.run/getting-started/installing/) chapter on the Gleam website.
3. Install [Docker Desktop](https://docs.docker.com/desktop/) or [Docker Engine](https://docs.docker.com/engine/install/).

### Obtaining a copy of Cake

Open a terminal of your choice to clone _Cake_:

```shell
git clone https://github.com/inoas/gleam-cake.git
cd gleam-cake
```

### Starting the docker compose setup for example apps

Open a terminal of your choice and within the `gleam-cake` directory cloned above:

```shell
cd docs
cd demo-apps
cd docker-setup-for-examples
bin/docker/attached
```

## Start the example app

```shell
cd 01_demo_select_and_decode # or any other example app
gleam run
```

### Available demos

- [`SELECT` and decode into Cats](demo-apps/01_demo_select_and_decode/README.md)

---

If you want to edit and change the examples to try and explore _Cake_ you may chose whatever code editor you prefer but _Cake_ recommends chosing either [Zed](https://zed.dev/) or [Visual Studio Code](https://code.visualstudio.com/) — both feature _Gleam_ plugins and thus _Gleam_ specific _Language Server Protocol_ support — especially if you are new to _Gleam_.

To just explore a single example app, open just that app in your editor, so that the _Gleam_ LSP can pick up that example projects's `gleam.toml` file.

For example if you have `Zed` or `Visual Studio Code` installed you may run one of these form the `gleam-cake` directory cloned above:

- `code docs/demo-apps/01_demo_select_and_decode`
- `zed docs/demo-apps/01_demo_select_and_decode`

## TODOs

- Maybe move Erlang, Rebar and Gleam requirement into docker compose.

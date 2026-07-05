# Clojure CLI — use dnf5 so java is immediately available when the installer
# runs; use --prefix /usr (ostree has no /usr/local/bin)
RUN dnf5 install -y java-25-openjdk && \
    dnf5 clean all && \
    curl -fsSL "https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh" \
      -o /tmp/clojure-install.sh && \
    chmod +x /tmp/clojure-install.sh && \
    /tmp/clojure-install.sh --prefix /usr && \
    rm /tmp/clojure-install.sh && \
    ostree container commit

# clj-new — registers seancorfield/clj-new as a `clojure -T clj-new` tool for
# scaffolding new projects/templates. The registration lives under $HOME
# (~/.clojure/tools/tools.edn), same as any `clojure -Ttools install`; unlike
# the system-wide installs below, it only takes effect for whichever user's
# $HOME it's run under.
RUN clojure -Ttools install-latest :lib com.github.seancorfield/clj-new :as clj-new && \
    ostree container commit

# babashka: fast-starting Clojure scripting runtime; bbin (next step) needs
# `bb` on PATH to run its own scripts. Static-binary release, same
# latest-tag-via-API pattern used for whis/trufflehog in 030-cli-tools.
RUN BB_VERSION=$(curl -sL "https://api.github.com/repos/babashka/babashka/releases/latest" | \
      jq -r '.tag_name') && \
    curl -fsSL "https://github.com/babashka/babashka/releases/download/${BB_VERSION}/babashka-${BB_VERSION#v}-linux-amd64-static.tar.gz" \
    | tar -xz -C /usr/bin bb && \
    ostree container commit

# bbin — installs standalone Babashka scripts as commands (used below for
# clojure-mcp-light and clj-paren-repair). It's itself a `bb` script fetched
# straight from the repo; babashka/bbin has no GitHub Releases, so the tags
# API stands in for the "latest" lookup used elsewhere. BABASHKA_BBIN_BIN_DIR
# pins installed tools to /usr/bin instead of the default ~/.local/bin, so
# they land somewhere every user's PATH sees — same reasoning as the
# linuxbrew prefix in 050-package-managers.
RUN BBIN_VERSION=$(curl -sL "https://api.github.com/repos/babashka/bbin/tags" | \
      jq -r '.[0].name') && \
    curl -fsSL "https://raw.githubusercontent.com/babashka/bbin/${BBIN_VERSION}/bbin" \
      -o /usr/bin/bbin && \
    chmod +x /usr/bin/bbin && \
    ostree container commit

# clojure-mcp-light + clj-paren-repair (bhauman/clojure-mcp-light) — MCP
# server and paren-balancing helper for agentic Clojure workflows.
# https://www.iwillig.me/agentic-engineering-with-clojure/agentic-toolchain.html
RUN BABASHKA_BBIN_BIN_DIR=/usr/bin bbin install \
      https://github.com/bhauman/clojure-mcp-light.git \
      --tag v0.2.1 && \
    BABASHKA_BBIN_BIN_DIR=/usr/bin bbin install \
      https://github.com/bhauman/clojure-mcp-light.git \
      --tag v0.2.1 \
      --as clj-paren-repair \
      --main-opts '["-m" "clojure-mcp-light.paren-repair"]' && \
    ostree container commit

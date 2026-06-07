# Claude Code Web Environment Observation
**Date:** 2026-06-07  
**Session:** cse_016xn2LhYmHpwkBkaV12JwWs  
**Container:** container_01CnSnqy8nXKRFuu4Czjf3fy--claude_code_remote--c864ce  
**Image:** sandbox-ccr-default:74306e8bfdefb9f88fc0b5f3d4940d7086b3d3bb

---

## `check-tools` Output

`check-tools` is a system built-in at `/usr/local/bin/check-tools` (not a project script).
The project's `bin/` directory contains: `brakeman`, `bundler-audit`, `check-worktree`,
`ci`, `dev`, `docker-entrypoint`, `importmap`, `jobs`, `kamal`, `rails`, `rake`,
`rotate-master-key`, `rubocop`, `setup`, `thrust`, `worktree`

```
   _____ _                 _        _____           _
  / ____| |               | |      / ____|         | |
 | |    | | __ _ _   _  __| | ___  | |     ___   __| | ___
 | |    | |/ _` | | | |/ _` |/ _ \ | |    / _ \ / _` |/ _ \
 | |____| | (_| | |_| | (_| |  __/ | |___| (_) | (_| |  __/
  \_____|_|\__,_|\__,_|\__,_|\___|  \_____\___/ \__,_|\___|

      Development Environment Tool Versions
      =====================================

=================== Python ===================
✅ python3: Python 3.11.15
✅ python: Python 3.11.15
✅ pip: pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.11)
✅ poetry: Poetry (version 2.3.3)
✅ uv: uv 0.8.17
✅ black: black, 26.3.1 (compiled: yes)
✅ mypy: mypy 1.19.1 (compiled: yes)
✅ pytest: pytest 9.0.2
✅ ruff: ruff 0.15.8

=================== NodeJS ===================
✅ node: v22.22.2

->       system
iojs -> N/A (default)
node -> stable (-> N/A) (default)
unstable -> N/A (default)
✅ nvm: available
✅ npm: 10.9.7
✅ yarn: 1.22.22
✅ pnpm: 10.33.0
✅ eslint: v10.1.0
✅ prettier: 3.8.1
✅ chromedriver: ChromeDriver 147.0.7727.24 (09d377d9438dc95267369f74a073acd81bdde38f-refs/branch-heads/7727@{#1413})

=================== Java ===================
✅ java: openjdk version "21.0.10" 2026-01-20
  OpenJDK Runtime Environment (build 21.0.10+7-Ubuntu-124.04)
  OpenJDK 64-Bit Server VM (build 21.0.10+7-Ubuntu-124.04, mixed mode, sharing)
✅ maven: Apache Maven 3.9.11 (3e54c93a704957b63ee3494413a2b544fd3d825b)
✅ gradle: Gradle 8.14.3

=================== Go ===================
✅ go: go version go1.24.7 linux/amd64

=================== Rust ===================
✅ rustc: rustc 1.94.1 (e408947bf 2026-03-25)
✅ cargo: cargo 1.94.1 (29ea6fb6a 2026-03-24)

=================== C/C++ Compilers ===================
✅ clang: Ubuntu clang version 18.1.3 (1ubuntu1)
✅ gcc: gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
✅ cmake: cmake version 3.28.3
✅ ninja: 1.11.1
✅ conan: Conan version 2.27.0

=================== Docker ===================
✅ docker: Docker version 29.3.1, build c2be9cc
✅ dockerd: Docker version 29.3.1, build f78c987
✅ docker compose: Docker Compose version v5.1.1

=================== Other Utilities ===================
✅ awk: mawk 1.3.4 20240123
✅ curl: curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
✅ git: git version 2.43.0
✅ grep: grep (GNU grep) 3.11
✅ gzip: gzip 1.12
✅ jq: jq-1.7
✅ make: GNU Make 4.3
✅ rg: ripgrep 14.1.0
✅ sed: sed (GNU sed) 4.9
✅ tar: tar (GNU tar) 1.35
✅ tmux: tmux 3.4
✅ yq: yq 0.0.0
✅ vim: VIM - Vi IMproved 9.1 (2024 Jan 02, compiled Mar 10 2026 09:13:01)
✅ nano:  GNU nano, version 7.2

✅ All tool validations passed
```

---

## System Profile

| Property | Value |
|---|---|
| OS | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Kernel | Linux vm 6.18.5 #2 SMP PREEMPT_DYNAMIC Wed Jan 14 17:56:08 UTC 2026 x86_64 |
| Architecture | x86_64 |
| CPUs | 4 |
| RAM | 15 GiB total, ~14 GiB free |
| Swap | None |
| Disk (/) | 252 GiB total, 7.1 GiB used, 31 GiB available (20% used) |
| Virtualisation | Firecracker microVM (virtio block devices, SWIOTLB) |

---

## Ruby Environment

### Installed Ruby Versions (via rbenv at /opt/rbenv)

| Version | Notes |
|---|---|
| 3.1.6 | |
| 3.2.6 | |
| **3.3.6** | **Newest / Active** |
| system | OS default |

**Active Ruby:** `ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [x86_64-linux]`  
**Binary:** `/usr/local/bin/ruby`  
**rbenv root:** `/opt/rbenv`

### Ruby Standard Library Gems (gem list, Ruby 3.3.6)

| Gem | Version |
|---|---|
| abbrev | 0.1.2 (default) |
| base64 | 0.2.0 (default) |
| benchmark | 0.3.0 (default) |
| bigdecimal | 3.1.5 (default) |
| bundler | 4.0.9, 2.5.22 (default) |
| cgi | 0.4.1 (default) |
| csv | 3.2.8 (default) |
| date | 3.3.4 (default) |
| debug | 1.9.2 |
| delegate | 0.3.1 (default) |
| did_you_mean | 1.6.3 (default) |
| digest | 3.1.1 (default) |
| drb | 2.2.0 (default) |
| english | 0.8.0 (default) |
| erb | 4.0.3 (default) |
| error_highlight | 0.6.0 (default) |
| etc | 1.4.3 (default) |
| fcntl | 1.1.0 (default) |
| fiddle | 1.1.2 (default) |
| fileutils | 1.7.2 (default) |
| find | 0.2.0 (default) |
| forwardable | 1.3.3 (default) |
| getoptlong | 0.2.1 (default) |
| io-console | 0.7.1 (default) |
| io-nonblock | 0.3.0 (default) |
| io-wait | 0.3.1 (default) |
| ipaddr | 1.2.6 (default) |
| irb | 1.13.1 (default) |
| json | 2.7.2 (default) |
| logger | 1.6.0 (default) |
| matrix | 0.4.2 |
| minitest | 5.20.0 |
| mutex_m | 0.2.0 (default) |
| net-ftp | 0.3.4 |
| net-http | 0.4.1 (default) |
| net-imap | 0.4.9.1 |
| net-pop | 0.1.2 |
| net-protocol | 0.2.2 (default) |
| net-smtp | 0.4.0.1 |
| nkf | 0.1.3 (default) |
| observer | 0.1.2 (default) |
| open-uri | 0.4.1 (default) |
| open3 | 0.2.1 (default) |
| openssl | 3.2.0 (default) |
| optparse | 0.4.0 (default) |
| ostruct | 0.6.0 (default) |
| pathname | 0.3.0 (default) |
| power_assert | 2.0.3 |
| pp | 0.5.0 (default) |
| prettyprint | 0.2.0 (default) |
| prime | 0.1.2 |
| prism | 0.19.0 (default) |
| pstore | 0.1.3 (default) |
| psych | 5.1.2 (default) |
| racc | 1.7.3 |
| rake | 13.1.0 |
| rbs | 3.4.0 |
| rdoc | 6.6.3.1 (default) |
| readline | 0.0.4 (default) |
| reline | 0.5.10 (default) |
| resolv | 0.3.0 (default) |
| resolv-replace | 0.1.1 (default) |
| rexml | 3.3.9 |
| rinda | 0.2.0 (default) |
| rss | 0.3.1 |
| ruby2_keywords | 0.0.5 (default) |
| securerandom | 0.3.1 (default) |
| set | 1.1.0 (default) |
| shellwords | 0.2.0 (default) |
| singleton | 0.2.0 (default) |
| stringio | 3.1.1 (default) |
| strscan | 3.0.9 (default) |
| syntax_suggest | 2.0.1 (default) |
| syslog | 0.1.2 (default) |
| tempfile | 0.2.1 (default) |
| test-unit | 3.6.1 |
| time | 0.3.0 (default) |
| timeout | 0.4.1 (default) |
| tmpdir | 0.2.0 (default) |
| tsort | 0.2.0 (default) |
| typeprof | 0.21.9 |
| un | 0.3.0 (default) |
| uri | 0.13.1 (default) |
| weakref | 0.1.3 (default) |
| yaml | 0.3.0 (default) |
| zlib | 3.1.1 (default) |

### Application Gems (Gemfile.lock — Rails 8.1.3 app)

Bundled with bundler 4.0.10. Primary dependencies:

| Gem | Version |
|---|---|
| rails | 8.1.3 |
| sqlite3 | 2.9.4 |
| puma | 8.0.2 |
| falcon | 0.55.5 |
| solid_queue | 1.4.0 |
| solid_cache | 1.0.10 |
| solid_cable | 4.0.0 |
| turbo-rails | 2.0.23 |
| stimulus-rails | 1.3.4 |
| importmap-rails | 2.2.3 |
| propshaft | 1.3.2 |
| jbuilder | 2.15.1 |
| kamal | 2.11.0 |
| thruster | 0.1.21 |
| bootsnap | 1.24.6 |
| brakeman | 8.0.4 |
| bundler-audit | 0.9.3 |
| rubocop-rails-omakase | 1.1.0 |
| capybara | 3.40.0 |
| selenium-webdriver | 4.44.0 |
| web-console | 4.3.0 |
| dotenv-rails | 3.2.0 |
| image_processing | 2.0.2 |
| async-job-adapter-active_job | 0.19.0 |
| debug | 1.11.1 |

Full resolved graph (all platforms including aarch64, arm, x86_64 darwin/linux):

action_text-trix 2.1.19, actioncable 8.1.3, actionmailbox 8.1.3,
actionmailer 8.1.3, actionpack 8.1.3, actiontext 8.1.3, actionview 8.1.3,
activejob 8.1.3, activemodel 8.1.3, activerecord 8.1.3, activestorage 8.1.3,
activesupport 8.1.3, addressable 2.9.0, ast 2.4.3, async 2.39.0,
async-container 0.35.1, async-http 0.95.1, async-http-cache 0.4.6,
async-job 0.11.1, async-job-adapter-active_job 0.19.0, async-pool 0.11.2,
async-service 0.24.1, async-utilization 0.4.0, bake 0.25.0, base64 0.3.0,
bcrypt_pbkdf 1.1.2, bigdecimal 4.1.2, bindex 0.8.1, bootsnap 1.24.6,
brakeman 8.0.4, builder 3.3.0, bundler-audit 0.9.3, capybara 3.40.0,
concurrent-ruby 1.3.6, connection_pool 3.0.2, console 1.36.0, crass 1.0.6,
date 3.5.1, debug 1.11.1, dotenv 3.2.0, dotenv-rails 3.2.0, drb 2.2.3,
ed25519 1.4.0, erb 6.0.4, erubi 1.13.1, et-orbi 1.4.0, falcon 0.55.5,
fiber-annotation 0.2.0, fiber-local 1.1.0, fiber-storage 1.0.1,
fugit 1.12.2, globalid 1.3.0, i18n 1.14.8, image_processing 2.0.2,
importmap-rails 2.2.3, io-console 0.8.2, io-endpoint 0.17.2, io-event 1.16.1,
io-stream 0.13.0, irb 1.18.0, jbuilder 2.15.1, json 2.19.8, kamal 2.11.0,
language_server-protocol 3.17.0.5, lint_roller 1.1.0, localhost 1.8.0,
logger 1.7.0, loofah 2.25.1, mail 2.9.0, mapping 1.1.3, marcel 1.2.1,
matrix 0.4.3, metrics 0.15.0, mini_mime 1.1.5, minitest 6.0.6, msgpack 1.8.1,
net-imap 0.6.4, net-pop 0.1.2, net-protocol 0.2.2, net-scp 4.1.0,
net-sftp 4.0.0, net-smtp 0.5.1, net-ssh 7.3.2, nio4r 2.7.5,
nokogiri 1.19.3 (multi-platform), openssl 4.0.2, ostruct 0.6.3,
parallel 2.1.0, parser 3.3.11.1, pp 0.6.3, prettyprint 0.2.0, prism 1.9.0,
propshaft 1.3.2, protocol-hpack 1.5.1, protocol-http 0.62.2,
protocol-http1 0.39.0, protocol-http2 0.26.0, protocol-rack 0.22.1,
protocol-url 0.4.0, psych 5.4.0, public_suffix 7.0.5, puma 8.0.2,
raabro 1.4.0, racc 1.8.1, rack 3.2.6, rack-session 2.1.2, rack-test 2.2.0,
rackup 2.3.1, rails 8.1.3, rails-dom-testing 2.3.0,
rails-html-sanitizer 1.7.0, railties 8.1.3, rainbow 3.1.1, rake 13.4.2,
rdoc 7.2.0, regexp_parser 2.12.0, reline 0.6.3, rexml 3.4.4,
rubocop 1.87.0, rubocop-ast 1.49.1, rubocop-performance 1.26.1,
rubocop-rails 2.35.3, rubocop-rails-omakase 1.1.0, ruby-progressbar 1.13.0,
rubyzip 3.3.1, samovar 2.4.1, securerandom 0.4.1, selenium-webdriver 4.44.0,
solid_cable 4.0.0, solid_cache 1.0.10, solid_queue 1.4.0,
sqlite3 2.9.4 (multi-platform), sshkit 1.25.0, stimulus-rails 1.3.4,
string-format 0.2.0, stringio 3.2.0, thor 1.5.0, thruster 0.1.21,
timeout 0.6.1, traces 0.18.2, tsort 0.2.0, turbo-rails 2.0.23,
tzinfo 2.0.6, unicode-display_width 3.2.0, unicode-emoji 4.2.0, uri 1.1.1,
useragent 0.16.11, web-console 4.3.0, websocket 1.2.11,
websocket-driver 0.8.1, websocket-extensions 0.1.5, xpath 3.2.0,
zeitwerk 2.8.2

---

## Other Language Runtimes

| Runtime | Version |
|---|---|
| Node.js | v22.22.2 (at /opt/node22) |
| Bun | 1.3.11 |
| Python | 3.11.15 (active); also 3.10, 3.12, 3.13 installed |
| Go | 1.24.7 linux/amd64 |
| Rust | 1.94.1 (e408947bf 2026-03-25) |
| Java | OpenJDK 21.0.10+7 (at /usr/lib/jvm/java-21-openjdk-amd64) |
| PHP | 8.4.19 |

---

## Environment Variables (non-credential)

```
AI_AGENT=claude-code_2-1-168_agent
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANT_IMAGE_REPOSITORY=sandbox-ccr-default
ANT_IMAGE_TAG=74306e8bfdefb9f88fc0b5f3d4940d7086b3d3bb
BUN_INSTALL=/root/.bun
BUN_OPTIONS=--smol
CCR_ENABLE_TRACING=true
CCR_SPAWN_TIMESTAMP_MS=1780802855008
CCR_TEST_GITPROXY=1
CLAUDECODE=1
CLAUDE_AFTER_LAST_COMPACT=true
CLAUDE_AUTO_BACKGROUND_TASKS=true
CLAUDE_CODE_ACCOUNT_UUID=731176d6-f4b3-41b7-9e4c-5c86e67eb2f4
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1
CLAUDE_CODE_BASE_REF=main
CLAUDE_CODE_CONTAINER_ID=container_01CnSnqy8nXKRFuu4Czjf3fy--claude_code_remote--c864ce
CLAUDE_CODE_DEBUG=true
CLAUDE_CODE_DIAGNOSTICS_FILE=/tmp/claude-code-2329037242.diag.log
CLAUDE_CODE_DISABLE_BUILTIN_ANTMCP=1
CLAUDE_CODE_ENTRYPOINT=remote_mobile
CLAUDE_CODE_ENVIRONMENT_RUNNER_VERSION=release-ba75b329f-ext
CLAUDE_CODE_EXECPATH=/opt/claude-code/bin/claude
CLAUDE_CODE_ORGANIZATION_UUID=000c6b6e-6320-45eb-89b5-649867ea5ec2
CLAUDE_CODE_POST_FOR_SESSION_INGRESS_V2=true
CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST=1
CLAUDE_CODE_PROXY_RESOLVES_HOSTS=true
CLAUDE_CODE_REMOTE=true
CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE=cloud_default
CLAUDE_CODE_REMOTE_SEND_KEEPALIVES=true
CLAUDE_CODE_REMOTE_SESSION_ID=cse_016xn2LhYmHpwkBkaV12JwWs
CLAUDE_CODE_SESSION_ID=c2718bdb-8fd0-587c-bb28-daf8c7fd6fdd
CLAUDE_CODE_TEE_SDK_STDOUT=true
CLAUDE_CODE_USER_EMAIL=adbust@gmail.com
CLAUDE_CODE_USE_CCR_V2=true
CLAUDE_CODE_VERSION=2.1.42
CLAUDE_CODE_WORKER_EPOCH=1
CLAUDE_EFFORT=high
CLAUDE_ENABLE_STREAM_WATCHDOG=1
CODESIGN_MCP_PORT=38977
COREPACK_ENABLE_AUTO_PIN=0
DEBIAN_FRONTEND=noninteractive
ENVRUNNER_SKIP_ACK=true
ENV_MANAGER_ENABLE_DIAG_LOGS=true
GIT_EDITOR=true
HOME=/root
IS_SANDBOX=yes
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
MCP_CONNECTION_NONBLOCKING=true
MCP_TOOL_TIMEOUT=60000
NODE_OPTIONS=--max-old-space-size=8192
NoDefaultCurrentDirectoryInExePath=1
OLDPWD=/
PATH=/root/.local/bin:/root/.cargo/bin:/usr/local/go/bin:/opt/node22/bin:/opt/maven/bin:/opt/gradle/bin:/opt/rbenv/bin:/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
PWD=/home/user/fizzbuzz_app
PYTHONUNBUFFERED=1
RBENV_ROOT=/opt/rbenv
RUSTUP_HOME=/root/.rustup
RUST_BACKTRACE=1
SHELL=/bin/bash
SHLVL=1
SKIP_PLUGIN_MARKETPLACE=true
TERM=linux
TRACEPARENT=00-a604e3293d42b1b022c6b3c0fa1d3346-869f6bfed1187eae-01
USE_BUILTIN_RIPGREP=false
USE_SHTTP_MCP=true
_=/usr/bin/env
```

---

## dmesg (boot tail)

```
[   32.724238] pci_bus 0000:00: resource 4 [mem 0xeec00000-0xeecfffff]
[   32.727379] pci_bus 0000:00: resource 5 [mem 0xc0001000-0xeebfffff window]
[   32.730792] pci_bus 0000:00: resource 6 [mem 0x4000000000-0x7fffffffff window]
[   32.734340] pci_bus 0000:00: resource 7 [io  0x0000-0x0cf7 window]
[   32.737423] pci_bus 0000:00: resource 8 [io  0x0d00-0xffff window]
[   32.740889] PCI: CLS 0 bytes, default 64
[   32.742872] PCI-DMA: Using software bounce buffering for IO (SWIOTLB)
[   32.742964] Unpacking initramfs...
[   32.746074] software IO TLB: No low mem
[   32.749847] RAPL PMU: API unit is 2^-32 Joules, 0 fixed counters, 10737418240 ms ovfl timer
[   32.754003] clocksource: tsc: mask: 0xffffffffffffffff max_cycles: 0x285c3ee517e, max_idle_ns: 440795257231 ns
[   32.759074] clocksource: Switched to clocksource tsc
[   32.761718] platform rtc_cmos: registered platform RTC device (no PNP device found)
[   32.768149] Freeing initrd memory: 4276K
[   32.771672] Initialise system trusted keyrings
[   32.774039] Key type blacklist registered
[   32.776207] workingset: timestamp_bits=36 max_order=22 bucket_order=0
[   32.779859] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[   32.783142] NFS: Registering the id_resolver key type
[   32.785735] Key type id_resolver registered
[   32.787853] Key type id_legacy registered
[   32.789947] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[   32.793351] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[   32.797270] fuse: init (API version 7.45)
[   32.799494] SGI XFS with ACLs, security attributes, quota, no debug enabled
[   32.812033] Key type asymmetric registered
[   32.814152] Asymmetric key parser 'x509' registered
[   32.816654] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 251)
[   32.820463] io scheduler mq-deadline registered
[   32.822790] io scheduler kyber registered
[   32.824868] io scheduler bfq registered
[   32.832791] virtio-pci 0000:00:01.0: enabling device (0000 -> 0002)
[   32.838795] virtio-pci 0000:00:02.0: enabling device (0000 -> 0002)
[   32.844790] virtio-pci 0000:00:03.0: enabling device (0000 -> 0002)
[   32.850742] virtio-pci 0000:00:04.0: enabling device (0000 -> 0002)
[   32.856808] virtio-pci 0000:00:05.0: enabling device (0000 -> 0002)
[   32.862944] virtio-pci 0000:00:06.0: enabling device (0000 -> 0002)
[   32.869111] virtio-pci 0000:00:07.0: enabling device (0000 -> 0002)
[   32.875259] Serial: 8250/16550 driver, 1 ports, IRQ sharing disabled
[   32.879008] 00:00: ttyS0 at I/O 0x3f8 (irq = 26, base_baud = 115200) is a 16550A
[   32.888414] loop: module loaded
[   32.890570] virtio_blk virtio0: 1/0/0 default/read/poll queues
[   32.895477] virtio_blk virtio0: [vda] 536870912 512-byte logical blocks (275 GB/256 GiB)
[   32.900371] virtio_blk virtio1: 1/0/0 default/read/poll queues
[   32.905221] virtio_blk virtio1: [vdb] 536870912 512-byte logical blocks (275 GB/256 GiB)
[   32.910076] virtio_blk virtio2: 1/0/0 default/read/poll queues
[   32.914903] virtio_blk virtio2: [vdc] 536870912 512-byte logical blocks (275 GB/256 GiB)
[   32.919816] virtio_blk virtio3: 1/0/0 default/read/poll queues
[   32.924685] virtio_blk virtio3: [vdd] 536870912 512-byte logical blocks (275 GB/256 GiB)
[   32.929585] virtio_blk virtio4: 1/0/0 default/read/poll queues
[   32.934495] virtio_blk virtio4: [vde] 536870912 512-byte logical blocks (275 GB/256 GiB)
[   32.939036] Loading iSCSI transport class v2.0-870.
[   32.941721] iscsi: registered transport (tcp)
[   32.943931] tun: Universal TUN/TAP device driver, 1.6
[   32.950630] intel_pstate: CPU model not supported
[   32.953057] hid: raw HID events driver (C) Jiri Kosina
[   32.956461] xt_time: kernel timezone is -0000
[   32.958783] Initializing XFRM netlink socket
[   32.960926] IPv6: Loaded, but administratively disabled, reboot required to enable
[   32.964677] NET: Registered PF_PACKET protocol family
[   32.967202] Bridge firewalling registered
[   32.969391] Key type dns_resolver registered
[   32.971623] NET: Registered PF_VSOCK protocol family
[   32.974421] IPI shorthand broadcast: enabled
[   32.978105] sched_clock: Marking stable (32620058035, 356521272)->(33496431320, -519852013)
[   32.982517] registered taskstats version 1
[   32.984917] Loading compiled-in X.509 certificates
[   32.989499] Demotion targets for Node 0: null
[   32.991862] Key type .fscrypt registered
[   32.993871] Key type fscrypt-provisioning registered
[   32.996861] Key type encrypted registered
[   32.999496] clk: Disabling unused clocks
[   33.009598] Freeing unused kernel image (initmem) memory: 2912K
[   33.011299] Write protecting the kernel read-only data: 20480k
[   33.019305] Freeing unused kernel image (text/rodata gap) memory: 1412K
[   33.022608] Freeing unused kernel image (rodata/data gap) memory: 272K
[   33.024451] Run /process_api as init process
[   33.025743]   with arguments:
[   33.025744]     /process_api
[   33.025745]     --firecracker-init
[   33.025746]     --addr
[   33.025746]     0.0.0.0:2024
[   33.025748]     --max-ws-buffer-size
[   33.025748]     32768
[   33.025749]     --block-local-connections
[   34.310111] virtio_blk virtio2: [vdc] new size: 40000 512-byte logical blocks (20.5 MB)
[   34.310111] virtio_blk virtio3: [vdd] new size: 1312 512-byte logical blocks (672 kB)
[   34.310659] virtio_blk virtio4: [vde] new size: 10952 512-byte logical blocks (5.61 MB)
[   34.311267] vdd: detected capacity change from 536870912 to 1312
[   34.311268] vde: detected capacity change from 536870912 to 10952
[   34.311299] virtio_blk virtio1: [vdb] new size: 126328 512-byte logical blocks (64.7 MB)
[   34.311476] vdb: detected capacity change from 536870912 to 126328
[   34.313556] virtio_blk virtio0: [vda] new size: 536870912 512-byte logical blocks (275 GB)
[   34.318438] vdc: detected capacity change from 536870912 to 40000
[   34.324878] random: crng reseeded due to virtual machine fork
[   34.368519] tokio-rt-worker (520): drop_caches: 3
[   34.409546] EXT4-fs (vda): mounted filesystem r/w without journal. Quota mode: none.
```

---

## Installed System Packages (686 total, Ubuntu 24.04 apt/dpkg)

```
adduser 3.137ubuntu1
adwaita-icon-theme 46.0-1
age 1.1.1-1ubuntu0.24.04.3
apt 2.8.3
apt-transport-https 2.8.3
at-spi2-common 2.52.0-1build1
autoconf 2.71-3
automake 1:1.16.5-1.3ubuntu1
autotools-dev 20220109.1
base-files 13ubuntu10.4
base-passwd 3.6.3build1
bash 5.2.21-2ubuntu4
bc 1.07.1-3ubuntu4
binutils 2.42-4ubuntu2.10
binutils-common:amd64 2.42-4ubuntu2.10
binutils-x86-64-linux-gnu 2.42-4ubuntu2.10
bison 2:3.8.2+dfsg-1build2
bsdutils 1:2.39.3-9ubuntu6.5
build-essential 12.10ubuntu1
bzip2 1.0.8-5.1build0.1
ca-certificates 20240203
ca-certificates-java 20240118
clang 1:18.0-59~exp2
clang-18 1:18.1.3-1ubuntu1
clang-format-18 1:18.1.3-1ubuntu1
clang-format:amd64 1:18.0-59~exp2
clang-tidy 1:18.0-59~exp2
clang-tidy-18 1:18.1.3-1ubuntu1
clang-tools-18 1:18.1.3-1ubuntu1
cmake 3.28.3-1build7
cmake-data 3.28.3-1build7
containerd.io 2.2.2-1~ubuntu.24.04~noble
coreutils 9.4-3ubuntu6.1
cpp 4:13.2.0-7ubuntu1
cpp-13 13.3.0-6ubuntu2~24.04.1
cpp-13-x86-64-linux-gnu 13.3.0-6ubuntu2~24.04.1
cpp-x86-64-linux-gnu 4:13.2.0-7ubuntu1
curl 8.5.0-2ubuntu10.8
dash 0.5.12-6ubuntu5
dbus 1.14.10-4ubuntu4.1
dbus-bin 1.14.10-4ubuntu4.1
dbus-daemon 1.14.10-4ubuntu4.1
dbus-session-bus-common 1.14.10-4ubuntu4.1
dbus-system-bus-common 1.14.10-4ubuntu4.1
dbus-user-session 1.14.10-4ubuntu4.1
dconf-gsettings-backend:amd64 0.40.0-4ubuntu0.1
dconf-service 0.40.0-4ubuntu0.1
debconf 1.5.86ubuntu1
debianutils 5.17build1
diffutils 1:3.10-1build1
dirmngr 2.4.4-2ubuntu17.4
distro-info-data 0.60ubuntu0.5
docker-buildx-plugin 0.31.1-1~ubuntu.24.04~noble
docker-ce 5:29.3.1-1~ubuntu.24.04~noble
docker-ce-cli 5:29.3.1-1~ubuntu.24.04~noble
docker-compose-plugin 5.1.1-1~ubuntu.24.04~noble
dpkg 1.22.6ubuntu6.5
dpkg-dev 1.22.6ubuntu6.5
e2fsprogs 1.47.0-2.4~exp1ubuntu4.1
file 1:5.45-3build1
findutils 4.9.0-5build1
fontconfig 2.15.0-1.1ubuntu2
fontconfig-config 2.15.0-1.1ubuntu2
fonts-dejavu-core 2.37-8
fonts-dejavu-mono 2.37-8
fonts-freefont-ttf 20211204+svn4273-2
fonts-ipafont-gothic 00303-21ubuntu1
fonts-liberation 1:2.1.5-3
fonts-noto-color-emoji 2.047-0ubuntu0.24.04.1
fonts-opensymbol 4:102.12+LibO24.2.7-0ubuntu0.24.04.4
fonts-tlwg-loma-otf 1:0.7.3-1
fonts-unifont 1:15.1.01-1build1
fonts-wqy-zenhei 0.9.45-8
g++ 4:13.2.0-7ubuntu1
g++-13 13.3.0-6ubuntu2~24.04.1
g++-13-x86-64-linux-gnu 13.3.0-6ubuntu2~24.04.1
g++-x86-64-linux-gnu 4:13.2.0-7ubuntu1
gcc 4:13.2.0-7ubuntu1
gcc-13 13.3.0-6ubuntu2~24.04.1
gcc-13-base:amd64 13.3.0-6ubuntu2~24.04.1
gcc-13-x86-64-linux-gnu 13.3.0-6ubuntu2~24.04.1
gcc-14-base:amd64 14.2.0-4ubuntu2~24.04.1
gcc-x86-64-linux-gnu 4:13.2.0-7ubuntu1
gdb 15.1-1ubuntu1~24.04.1
gir1.2-girepository-2.0:amd64 1.80.1-1
gir1.2-glib-2.0:amd64 2.80.0-6ubuntu3.8
gir1.2-packagekitglib-1.0 1.2.8-2ubuntu1.4
git 1:2.43.0-1ubuntu7.3
git-man 1:2.43.0-1ubuntu7.3
gnupg 2.4.4-2ubuntu17.4
gnupg-utils 2.4.4-2ubuntu17.4
gnupg2 2.4.4-2ubuntu17.4
gpg 2.4.4-2ubuntu17.4
gpg-agent 2.4.4-2ubuntu17.4
gpgconf 2.4.4-2ubuntu17.4
gpgsm 2.4.4-2ubuntu17.4
gpgv 2.4.4-2ubuntu17.4
grep 3.11-4build1
gtk-update-icon-cache 3.24.41-4ubuntu1.3
gzip 1.12-1ubuntu3.1
hicolor-icon-theme 0.17-2
hostname 3.23+nmu2ubuntu2
humanity-icon-theme 0.6.16
init-system-helpers 1.66ubuntu1
iptables 1.8.10-3ubuntu2
iso-codes 4.16.0-1
java-common 0.75+exp1
jq 1.7.1-3ubuntu0.24.04.1
keyboxd 2.4.4-2ubuntu17.4
less 590-2ubuntu2.1
libabsl20220623t64:amd64 20220623.1-3.1ubuntu3.2
libacl1:amd64 2.3.2-1build1.1
libaom3:amd64 3.8.2-2ubuntu0.1
libapparmor1:amd64 4.0.1really4.0.1-0ubuntu0.24.04.5
libappstream5:amd64 1.0.2-1build6
libapt-pkg6.0t64:amd64 2.8.3
libarchive13t64:amd64 3.7.2-2ubuntu0.5
libargon2-1:amd64 0~20190702+dfsg-4build1
libasan8:amd64 14.2.0-4ubuntu2~24.04.1
libasound2-data 1.2.11-1ubuntu0.2
libasound2t64:amd64 1.2.11-1ubuntu0.2
libassuan0:amd64 2.5.6-1build1
libatk-bridge2.0-0t64:amd64 2.52.0-1build1
libatk1.0-0t64:amd64 2.52.0-1build1
libatomic1:amd64 14.2.0-4ubuntu2~24.04.1
libatspi2.0-0t64:amd64 2.52.0-1build1
libattr1:amd64 1:2.5.2-1build1.1
libaudit-common 1:3.1.2-2.1build1.1
libaudit1:amd64 1:3.1.2-2.1build1.1
libavahi-client3:amd64 0.8-13ubuntu6.1
libavahi-common-data:amd64 0.8-13ubuntu6.1
libavahi-common3:amd64 0.8-13ubuntu6.1
libavif16:amd64 1.0.4-1ubuntu3
libbabeltrace1:amd64 1.5.11-3build3
libbinutils:amd64 2.42-4ubuntu2.10
libblkid-dev:amd64 2.39.3-9ubuntu6.5
libblkid1:amd64 2.39.3-9ubuntu6.5
libboost-iostreams1.83.0:amd64 1.83.0-2.1ubuntu3.2
libboost-locale1.83.0:amd64 1.83.0-2.1ubuntu3.2
libboost-thread1.83.0:amd64 1.83.0-2.1ubuntu3.2
libbrotli-dev:amd64 1.1.0-2build2
libbrotli1:amd64 1.1.0-2build2
libbsd0:amd64 0.12.1-1build1.1
libbz2-1.0:amd64 1.0.8-5.1build0.1
libbz2-dev:amd64 1.0.8-5.1build0.1
libc-bin 2.39-0ubuntu8.7
libc-dev-bin 2.39-0ubuntu8.7
libc6-dbg:amd64 2.39-0ubuntu8.7
libc6-dev:amd64 2.39-0ubuntu8.7
libc6:amd64 2.39-0ubuntu8.7
libcairo-gobject2:amd64 1.18.0-3build1
libcairo-script-interpreter2:amd64 1.18.0-3build1
libcairo2-dev:amd64 1.18.0-3build1
libcairo2:amd64 1.18.0-3build1
libcap-ng0:amd64 0.8.4-2build2
libcap2-bin 1:2.66-5ubuntu2.2
libcap2:amd64 1:2.66-5ubuntu2.2
libcc1-0:amd64 14.2.0-4ubuntu2~24.04.1
libclang-common-18-dev:amd64 1:18.1.3-1ubuntu1
libclang-cpp18 1:18.1.3-1ubuntu1
libclang1-18 1:18.1.3-1ubuntu1
libclucene-contribs1t64:amd64 2.3.3.4+dfsg-1.2ubuntu2
libclucene-core1t64:amd64 2.3.3.4+dfsg-1.2ubuntu2
libcolord2:amd64 1.4.7-1build2
libcom-err2:amd64 1.47.0-2.4~exp1ubuntu4.1
libcrypt-dev:amd64 1:4.4.36-4build1
libcrypt1:amd64 1:4.4.36-4build1
libcryptsetup12:amd64 2:2.7.0-1ubuntu4.2
libctf-nobfd0:amd64 2.42-4ubuntu2.10
libctf0:amd64 2.42-4ubuntu2.10
libcups2t64:amd64 2.4.7-1.2ubuntu7.9
libcurl3t64-gnutls:amd64 8.5.0-2ubuntu10.8
libcurl4t64:amd64 8.5.0-2ubuntu10.8
libdatrie1:amd64 0.2.13-3build1
libdav1d7:amd64 1.4.1-1build1
libdb-dev:amd64 1:5.3.21ubuntu2
libdb5.3-dev 5.3.28+dfsg2-7
libdb5.3t64:amd64 5.3.28+dfsg2-7
libdbus-1-3:amd64 1.14.10-4ubuntu4.1
libdconf1:amd64 0.40.0-4ubuntu0.1
libde265-0:amd64 1.0.15-1build3
libdebconfclient0:amd64 0.271ubuntu3
libdebuginfod-common 0.190-1.1ubuntu0.1
libdebuginfod1t64:amd64 0.190-1.1ubuntu0.1
libdeflate0:amd64 1.19-1build1.1
libdevmapper1.02.1:amd64 2:1.02.185-3ubuntu3.2
libdpkg-perl 1.22.6ubuntu6.5
libdrm-amdgpu1:amd64 2.4.125-1ubuntu0.1~24.04.1
libdrm-common 2.4.125-1ubuntu0.1~24.04.1
libdrm-intel1:amd64 2.4.125-1ubuntu0.1~24.04.1
libdrm2:amd64 2.4.125-1ubuntu0.1~24.04.1
libduktape207:amd64 2.7.0+tests-0ubuntu3
libdw1t64:amd64 0.190-1.1ubuntu0.1
libedit2:amd64 3.1-20230828-1build1
libelf1t64:amd64 0.190-1.1ubuntu0.1
libeot0:amd64 0.01-5build3
libepoxy0:amd64 1.5.10-1build1
liberror-perl 0.17029-2
libevent-core-2.1-7t64:amd64 2.1.12-stable-9ubuntu2
libexpat1-dev:amd64 2.6.1-2ubuntu0.4
libexpat1:amd64 2.6.1-2ubuntu0.4
libext2fs2t64:amd64 1.47.0-2.4~exp1ubuntu4.1
libexttextcat-2.0-0:amd64 3.4.7-1build1
libexttextcat-data 3.4.7-1build1
libfdisk1:amd64 2.39.3-9ubuntu6.5
libffi-dev:amd64 3.4.6-1build1
libffi8:amd64 3.4.6-1build1
libfontconfig-dev:amd64 2.15.0-1.1ubuntu2
libfontconfig1:amd64 2.15.0-1.1ubuntu2
libfontenc1:amd64 1:1.1.8-1build1
libfreetype-dev:amd64 2.13.2+dfsg-1ubuntu0.1
libfreetype6:amd64 2.13.2+dfsg-1ubuntu0.1
libfribidi0:amd64 1.0.13-3build1
libgav1-1:amd64 0.18.0-1build3
libgbm1:amd64 25.2.8-0ubuntu0.24.04.1
libgc1:amd64 1:8.2.6-1build1
libgcc-13-dev:amd64 13.3.0-6ubuntu2~24.04.1
libgcc-s1:amd64 14.2.0-4ubuntu2~24.04.1
libgcrypt20:amd64 1.10.3-2build1
libgd3:amd64 2.3.3-13+ubuntu24.04.1+deb.sury.org+1
libgdbm-compat-dev:amd64 1.23-5.1build1
libgdbm-compat4t64:amd64 1.23-5.1build1
libgdbm-dev:amd64 1.23-5.1build1
libgdbm6t64:amd64 1.23-5.1build1
libgdk-pixbuf-2.0-0:amd64 2.42.10+dfsg-3ubuntu3.2
libgdk-pixbuf2.0-common 2.42.10+dfsg-3ubuntu3.2
libgif7:amd64 5.2.2-1ubuntu1
libgirepository-1.0-1:amd64 1.80.1-1
libgirepository-2.0-0:amd64 2.80.0-6ubuntu3.8
libgl1-mesa-dri:amd64 25.2.8-0ubuntu0.24.04.1
libgl1:amd64 1.7.0-1build1
libglib2.0-0t64:amd64 2.80.0-6ubuntu3.8
libglib2.0-bin 2.80.0-6ubuntu3.8
libglib2.0-data 2.80.0-6ubuntu3.8
libglib2.0-dev-bin 2.80.0-6ubuntu3.8
libglib2.0-dev:amd64 2.80.0-6ubuntu3.8
libglvnd0:amd64 1.7.0-1build1
libglx-mesa0:amd64 25.2.8-0ubuntu0.24.04.1
libglx0:amd64 1.7.0-1build1
libgmp10:amd64 2:6.3.0+dfsg-2ubuntu6.1
libgnutls30t64:amd64 3.8.3-1.1ubuntu3.5
libgomp1:amd64 14.2.0-4ubuntu2~24.04.1
libgpg-error0:amd64 1.47-3build2.1
libgpgme11t64:amd64 1.18.0-4.1ubuntu4
libgpgmepp6t64:amd64 1.18.0-4.1ubuntu4
libgpm2:amd64 1.20.7-11
libgprofng0:amd64 2.42-4ubuntu2.10
libgraphite2-3:amd64 1.3.14-2build1
libgssapi-krb5-2:amd64 1.20.1-6ubuntu2.6
libgstreamer-plugins-base1.0-0:amd64 1.24.2-1ubuntu0.4
libgstreamer1.0-0:amd64 1.24.2-1ubuntu0.1
libgtk-3-0t64:amd64 3.24.41-4ubuntu1.3
libgtk-3-common 3.24.41-4ubuntu1.3
libharfbuzz-icu0:amd64 8.3.0-2build2
libharfbuzz0b:amd64 8.3.0-2build2
libheif-plugin-aomdec:amd64 1.17.6-1ubuntu4.2
libheif-plugin-libde265:amd64 1.17.6-1ubuntu4.2
libheif1:amd64 1.17.6-1ubuntu4.2
libhogweed6t64:amd64 3.9.1-2.2build1.1
libhunspell-1.7-0:amd64 1.7.2+really1.7.2-10build3
libhwasan0:amd64 14.2.0-4ubuntu2~24.04.1
libhyphen0:amd64 2.8.8-7build3
libice-dev:amd64 2:1.0.10-1build3
libice6:amd64 2:1.0.10-1build3
libicu74:amd64 74.2-1ubuntu3.1
libidn2-0:amd64 2.3.7-2build1.1
libimagequant0:amd64 2.18.0-1build1
libip4tc2:amd64 1.8.10-3ubuntu2
libip6tc2:amd64 1.8.10-3ubuntu2
libipt2 2.0.6-1build1
libisl23:amd64 0.26-3build1.1
libitm1:amd64 14.2.0-4ubuntu2~24.04.1
libjansson4:amd64 2.14-2build2
libjbig0:amd64 2.1-6.1ubuntu2
libjemalloc2:amd64 5.3.0-2build1
libjpeg-turbo8:amd64 2.1.5-2ubuntu2
libjpeg8:amd64 8c-2ubuntu11
libjq1:amd64 1.7.1-3ubuntu0.24.04.1
libjs-jquery 3.6.1+dfsg+~3.5.14-1
libjs-sphinxdoc 7.2.6-6
libjs-underscore 1.13.4~dfsg+~1.11.4-3
libjson-c5:amd64 0.17-1build1
libjson-perl 4.10000-1
libjsoncpp25:amd64 1.9.5-6build1
libk5crypto3:amd64 1.20.1-6ubuntu2.6
libkeyutils1:amd64 1.6.3-3build1
libkmod2:amd64 31+20240202-2ubuntu7.1
libkrb5-3:amd64 1.20.1-6ubuntu2.6
libkrb5support0:amd64 1.20.1-6ubuntu2.6
libksba8:amd64 1.6.6-1build1
liblangtag-common 0.6.7-1build2
liblangtag1:amd64 0.6.7-1build2
liblcms2-2:amd64 2.14-2build1
libldap2:amd64 2.6.10+dfsg-0ubuntu0.24.04.1
liblerc4:amd64 4.0.0+ds-4ubuntu2
liblldb-18 1:18.1.3-1ubuntu1
libllvm17t64:amd64 1:17.0.6-9ubuntu1
libllvm18:amd64 1:18.1.3-1ubuntu1
libllvm20:amd64 1:20.1.2-0ubuntu1~24.04.2
liblsan0:amd64 14.2.0-4ubuntu2~24.04.1
libltdl7:amd64 2.4.7-7build1
liblz4-1:amd64 1.9.4-1build1.1
liblzf1:amd64 3.6-4
liblzma-dev:amd64 5.6.1+really5.4.5-1ubuntu0.2
liblzma5:amd64 5.6.1+really5.4.5-1ubuntu0.2
liblzo2-2:amd64 2.10-2build4
libmagic-mgc 1:5.45-3build1
libmagic1t64:amd64 1:5.45-3build1
libmd0:amd64 1.1.0-2build1.1
libmhash2:amd64 0.9.9.9-9build3
libmnl0:amd64 1.0.5-2build1
libmount-dev:amd64 2.39.3-9ubuntu6.5
libmount1:amd64 2.39.3-9ubuntu6.5
libmpc3:amd64 1.3.1-1build1.1
libmpfr6:amd64 4.2.1-1build1.1
libmythes-1.2-0:amd64 2:1.2.5-1build1
libncurses-dev:amd64 6.4+20240113-1ubuntu2
libncurses6:amd64 6.4+20240113-1ubuntu2
libncursesw6:amd64 6.4+20240113-1ubuntu2
libnetfilter-conntrack3:amd64 1.0.9-6build1
libnettle8t64:amd64 3.9.1-2.2build1.1
libnfnetlink0:amd64 1.0.2-2build1
libnftables1:amd64 1.0.9-1ubuntu0.1
libnftnl11:amd64 1.2.6-2build1
libnghttp2-14:amd64 1.59.0-1ubuntu0.2
libnpth0t64:amd64 1.6-3.1build1
libnspr4:amd64 2:4.35-1.1build1
libnss3:amd64 2:3.98-1ubuntu0.1
libobjc-13-dev:amd64 13.3.0-6ubuntu2~24.04.1
libobjc4:amd64 14.2.0-4ubuntu2~24.04.1
libonig5:amd64 6.9.9-1build1
libopenjp2-7:amd64 2.5.0-2ubuntu0.4
liborc-0.4-0t64:amd64 1:0.4.38-1ubuntu0.1
liborcus-0.18-0:amd64 0.19.2-3build3
liborcus-parser-0.18-0:amd64 0.19.2-3build3
libp11-kit0:amd64 0.25.3-4ubuntu2.1
libpackagekit-glib2-18:amd64 1.2.8-2ubuntu1.4
libpam-modules-bin 1.5.3-5ubuntu5.5
libpam-modules:amd64 1.5.3-5ubuntu5.5
libpam-runtime 1.5.3-5ubuntu5.5
libpam-systemd:amd64 255.4-1ubuntu8.14
libpam0g:amd64 1.5.3-5ubuntu5.5
libpango-1.0-0:amd64 1.52.1+ds-1build1
libpangocairo-1.0-0:amd64 1.52.1+ds-1build1
libpangoft2-1.0-0:amd64 1.52.1+ds-1build1
libpciaccess0:amd64 0.17-3ubuntu0.24.04.2
libpcre2-16-0:amd64 10.42-4ubuntu2.1
libpcre2-32-0:amd64 10.42-4ubuntu2.1
libpcre2-8-0:amd64 10.42-4ubuntu2.1
libpcre2-dev:amd64 10.42-4ubuntu2.1
libpcre2-posix3:amd64 10.42-4ubuntu2.1
libpcsclite1:amd64 2.0.3-1build1
libperl5.38t64:amd64 5.38.2-3.2ubuntu0.2
libpfm4:amd64 4.13.0+git32-g0d4ed0e-1
libpixman-1-0:amd64 0.42.2-1build1
libpixman-1-dev:amd64 0.42.2-1build1
libpkgconf3:amd64 1.8.1-2build1
libpng-dev:amd64 1.6.43-5ubuntu0.5
libpng16-16t64:amd64 1.6.43-5ubuntu0.5
libpolkit-agent-1-0:amd64 124-2ubuntu1.24.04.2
libpolkit-gobject-1-0:amd64 124-2ubuntu1.24.04.2
libpoppler134:amd64 24.02.0-1ubuntu9.8
libpq5:amd64 16.13-0ubuntu0.24.04.1
libproc2-0:amd64 2:4.0.4-4ubuntu3.2
libpsl5t64:amd64 0.21.2-1.1build1
libpthread-stubs0-dev:amd64 0.4-1build3
libpython3-dev:amd64 3.12.3-0ubuntu2.1
libpython3-stdlib:amd64 3.12.3-0ubuntu2.1
libpython3.10-dev:amd64 3.10.20-1+noble1
libpython3.10-minimal:amd64 3.10.20-1+noble1
libpython3.10-stdlib:amd64 3.10.20-1+noble1
libpython3.10:amd64 3.10.20-1+noble1
libpython3.11-dev:amd64 3.11.15-1+noble1
libpython3.11-minimal:amd64 3.11.15-1+noble1
libpython3.11-stdlib:amd64 3.11.15-1+noble1
libpython3.11:amd64 3.11.15-1+noble1
libpython3.12-dev:amd64 3.12.3-1ubuntu0.12
libpython3.12-minimal:amd64 3.12.3-1ubuntu0.12
libpython3.12-stdlib:amd64 3.12.3-1ubuntu0.12
libpython3.12t64:amd64 3.12.3-1ubuntu0.12
libpython3.13-dev:amd64 3.13.12-1+noble1
libpython3.13-stdlib:amd64 3.13.12-1+noble1
libpython3.13:amd64 3.13.12-1+noble1
libquadmath0:amd64 14.2.0-4ubuntu2~24.04.1
libraptor2-0:amd64 2.0.16-3ubuntu0.1
librasqal3t64:amd64 0.9.33-2.1build1
librav1e0:amd64 0.7.1-2
librdf0t64:amd64 1.0.17-3.1ubuntu3
libreadline-dev:amd64 8.2-4build1
libreadline8t64:amd64 8.2-4build1
libreoffice-common 4:24.2.7-0ubuntu0.24.04.4
libreoffice-core 4:24.2.7-0ubuntu0.24.04.4
libreoffice-style-colibre 4:24.2.7-0ubuntu0.24.04.4
libreoffice-uiconfig-common 4:24.2.7-0ubuntu0.24.04.4
librevenge-0.0-0:amd64 0.0.5-3build1
librhash0:amd64 1.4.3-3build1
librtmp1:amd64 2.4+20151223.gitfa8646d.1-2build7
libsasl2-2:amd64 2.1.28+dfsg1-5ubuntu3.1
libsasl2-modules-db:amd64 2.1.28+dfsg1-5ubuntu3.1
libseccomp2:amd64 2.5.5-1ubuntu3.1
libselinux1-dev:amd64 3.5-2ubuntu2.1
libselinux1:amd64 3.5-2ubuntu2.1
libsemanage-common 3.5-1build5
libsemanage2:amd64 3.5-1build5
libsensors-config 1:3.6.0-9build1
libsensors5:amd64 1:3.6.0-9build1
libsepol-dev:amd64 3.5-2build1
libsepol2:amd64 3.5-2build1
libsframe1:amd64 2.42-4ubuntu2.10
libsharpyuv0:amd64 1.3.2-0.4build3
libsm-dev:amd64 2:1.2.3-1build3
libsm6:amd64 2:1.2.3-1build3
libsmartcols1:amd64 2.39.3-9ubuntu6.5
libsodium23:amd64 1.0.18-1ubuntu0.24.04.1
libsource-highlight-common 3.1.9-4.3build1
libsource-highlight4t64:amd64 3.1.9-4.3build1
libsqlite3-0:amd64 3.45.1-1ubuntu2.5
libsqlite3-dev:amd64 3.45.1-1ubuntu2.5
libss2:amd64 1.47.0-2.4~exp1ubuntu4.1
libssh-4:amd64 0.10.6-2ubuntu0.4
libssl-dev:amd64 3.0.13-0ubuntu3.7
libssl3t64:amd64 3.0.13-0ubuntu3.7
libstdc++-13-dev:amd64 13.3.0-6ubuntu2~24.04.1
libstdc++6:amd64 14.2.0-4ubuntu2~24.04.1
libstemmer0d:amd64 2.2.0-4build1
libsvtav1enc1d1:amd64 1.7.0+dfsg-2build1
libsystemd-shared:amd64 255.4-1ubuntu8.14
libsystemd0:amd64 255.4-1ubuntu8.14
libtasn1-6:amd64 4.19.0-3ubuntu0.24.04.2
libthai-data 0.1.29-2build1
libthai0:amd64 0.1.29-2build1
libtiff6:amd64 4.5.1+git230720-4ubuntu2.5
libtinfo6:amd64 6.4+20240113-1ubuntu2
libtirpc-common 1.3.4+ds-1.1build1
libtirpc3t64:amd64 1.3.4+ds-1.1build1
libtool 2.4.7-7build1
libtsan2:amd64 14.2.0-4ubuntu2~24.04.1
libubsan1:amd64 14.2.0-4ubuntu2~24.04.1
libudev1:amd64 255.4-1ubuntu8.14
libunistring5:amd64 1.1-2build1.1
libuno-cppu3t64 4:24.2.7-0ubuntu0.24.04.4
libuno-cppuhelpergcc3-3t64 4:24.2.7-0ubuntu0.24.04.4
libuno-purpenvhelpergcc3-3t64 4:24.2.7-0ubuntu0.24.04.4
libuno-sal3t64 4:24.2.7-0ubuntu0.24.04.4
libuno-salhelpergcc3-3t64 4:24.2.7-0ubuntu0.24.04.4
libunwind8:amd64 1.6.2-3build1.1
libutempter0:amd64 1.2.1-3build1
libuuid1:amd64 2.39.3-9ubuntu6.5
libuv1t64:amd64 1.48.0-1.1build1
libvulkan1:amd64 1.3.275.0-1build1
libwayland-client0:amd64 1.22.0-2.1build1
libwayland-cursor0:amd64 1.22.0-2.1build1
libwayland-egl1:amd64 1.22.0-2.1build1
libwebp7:amd64 1.3.2-0.4build3
libx11-6:amd64 2:1.8.7-1build1
libx11-data 2:1.8.7-1build1
libx11-dev:amd64 2:1.8.7-1build1
libx11-xcb1:amd64 2:1.8.7-1build1
libxau-dev:amd64 1:1.0.9-1build6
libxau6:amd64 1:1.0.9-1build6
libxaw7:amd64 2:1.0.14-1build2
libxcb-dri3-0:amd64 1.15-1ubuntu2
libxcb-glx0:amd64 1.15-1ubuntu2
libxcb-present0:amd64 1.15-1ubuntu2
libxcb-randr0:amd64 1.15-1ubuntu2
libxcb-render0-dev:amd64 1.15-1ubuntu2
libxcb-render0:amd64 1.15-1ubuntu2
libxcb-shm0-dev:amd64 1.15-1ubuntu2
libxcb-shm0:amd64 1.15-1ubuntu2
libxcb-sync1:amd64 1.15-1ubuntu2
libxcb-xfixes0:amd64 1.15-1ubuntu2
libxcb1-dev:amd64 1.15-1ubuntu2
libxcb1:amd64 1.15-1ubuntu2
libxcomposite1:amd64 1:0.4.5-1build3
libxcursor1:amd64 1:1.2.1-1build1
libxdamage1:amd64 1:1.1.6-1build1
libxdmcp-dev:amd64 1:1.1.3-0ubuntu6
libxdmcp6:amd64 1:1.1.3-0ubuntu6
libxext-dev:amd64 2:1.3.4-1build2
libxext6:amd64 2:1.3.4-1build2
libxfixes3:amd64 1:6.0.0-2build1
libxfont2:amd64 1:2.0.6-1build1
libxi6:amd64 2:1.8.1-1build1
libxinerama1:amd64 2:1.1.4-3build1
libxkbcommon0:amd64 1.6.0-1build1
libxkbfile1:amd64 1:1.1.0-1build4
libxml2-utils 2.9.14+dfsg-1.3ubuntu3.7
libxml2:amd64 2.9.14+dfsg-1.3ubuntu3.7
libxmlb2:amd64 0.3.18-1
libxmlsec1t64-nss:amd64 1.2.39-5build2
libxmlsec1t64:amd64 1.2.39-5build2
libxmu6:amd64 2:1.1.3-3build2
libxmuu1:amd64 2:1.1.3-3build2
libxpm4:amd64 1:3.5.17-1build2
libxrandr2:amd64 2:1.5.2-2build1
libxrender-dev:amd64 1:0.9.10-1.1build1
libxrender1:amd64 1:0.9.10-1.1build1
libxshmfence1:amd64 1.3-1build5
libxslt1.1:amd64 1.1.39-0exp1ubuntu0.24.04.3
libxt6t64:amd64 1:1.2.1-1.2build1
libxtables12:amd64 1.8.10-3ubuntu2
libxtst6:amd64 2:1.2.3-1.1build1
libxxf86vm1:amd64 1:1.1.4-1build4
libxxhash0:amd64 0.8.2-2build1
libyajl2:amd64 2.1.0-5build1
libyaml-0-2:amd64 0.2.5-1build1
libyaml-dev:amd64 0.2.5-1build1
libyuv0:amd64 0.0~git202401110.af6ac82-1
libzip4t64:amd64 1.7.3-1.1ubuntu2
libzstd1:amd64 1.5.5+dfsg2-2build1.1
linux-libc-dev:amd64 6.8.0-106.106
lld-18 1:18.1.3-1ubuntu1
lld:amd64 1:18.0-59~exp2
lldb-18 1:18.1.3-1ubuntu1
lldb:amd64 1:18.0-59~exp2
llvm 1:18.0-59~exp2
llvm-18 1:18.1.3-1ubuntu1
llvm-18-linker-tools 1:18.1.3-1ubuntu1
llvm-18-runtime 1:18.1.3-1ubuntu1
llvm-runtime:amd64 1:18.0-59~exp2
locales 2.39-0ubuntu8.7
login 1:4.13+dfsg1-4ubuntu3.2
logsave 1.47.0-2.4~exp1ubuntu4.1
lsb-release 12.0-2
lsof 4.95.0-1build3
lto-disabled-list 47
m4 1.4.19-4build1
make 4.3-4.1build2
mawk 1.3.4.20240123-1build1
media-types 10.1.0
mesa-libgallium:amd64 25.2.8-0ubuntu0.24.04.1
mount 2.39.3-9ubuntu6.5
nano 7.2-2ubuntu0.1
ncurses-base 6.4+20240113-1ubuntu2
ncurses-bin 6.4+20240113-1ubuntu2
netbase 6.4
netcat-openbsd 1.226-1ubuntu2
nftables 1.0.9-1ubuntu0.1
ninja-build 1.11.1-2
openjdk-21-jdk-headless:amd64 21.0.10+7-1~24.04
openjdk-21-jdk:amd64 21.0.10+7-1~24.04
openjdk-21-jre-headless:amd64 21.0.10+7-1~24.04
openjdk-21-jre:amd64 21.0.10+7-1~24.04
openssl 3.0.13-0ubuntu3.7
packagekit 1.2.8-2ubuntu1.4
passwd 1:4.13+dfsg1-4ubuntu3.2
patch 2.7.6-7build3
perl 5.38.2-3.2ubuntu0.2
perl-base 5.38.2-3.2ubuntu0.2
perl-modules-5.38 5.38.2-3.2ubuntu0.2
php-common 2:101~+ubuntu24.04.1+deb.sury.org+1
php8.4-cli 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-common 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-curl 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-dev 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-gd 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-igbinary 3.2.16-6+ubuntu24.04.1+deb.sury.org+1
php8.4-intl 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-mbstring 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-mysql 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-opcache 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-pgsql 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-readline 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-redis 6.3.0-2+ubuntu24.04.1+deb.sury.org+1
php8.4-sqlite3 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-xml 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
php8.4-zip 8.4.19-1+ubuntu24.04.1+deb.sury.org+1
pinentry-curses 1.2.1-3ubuntu5
pkg-config:amd64 1.8.1-2build1
pkgconf-bin 1.8.1-2build1
pkgconf:amd64 1.8.1-2build1
polkitd 124-2ubuntu1.24.04.2
postgresql-16 16.13-0ubuntu0.24.04.1
postgresql-client-16 16.13-0ubuntu0.24.04.1
postgresql-client-common 257build1.1
postgresql-common 257build1.1
procps 2:4.0.4-4ubuntu3.2
psmisc 23.7-1build1
python-apt-common 2.7.7ubuntu5.2
python3 3.12.3-0ubuntu2.1
python3-apt 2.7.7ubuntu5.2
python3-argcomplete 3.1.4-1ubuntu0.1
python3-blinker 1.7.0-1
python3-cffi-backend:amd64 1.16.0-2build1
python3-cryptography 41.0.7-4ubuntu0.4
python3-dbus 1.3.2-5build3
python3-dev 3.12.3-0ubuntu2.1
python3-distro 1.9.0-1
python3-gi 3.48.2-1
python3-httplib2 0.20.4-3
python3-jwt 2.7.0-1ubuntu0.1
python3-launchpadlib 1.11.0-6
python3-lazr.restfulclient 0.14.6-1
python3-lazr.uri 1.0.6-3
python3-lldb-18 1:18.1.3-1ubuntu1
python3-minimal 3.12.3-0ubuntu2.1
python3-oauthlib 3.2.2-1
python3-packaging 24.0-1
python3-pip 24.0+dfsg-1ubuntu1.3
python3-pip-whl 24.0+dfsg-1ubuntu1.3
python3-pkg-resources 68.1.2-2ubuntu1.2
python3-pyparsing 3.1.1-1
python3-setuptools 68.1.2-2ubuntu1.2
python3-setuptools-whl 68.1.2-2ubuntu1.2
python3-six 1.16.0-4
python3-software-properties 0.99.49.4
python3-toml 0.10.2-1
python3-uno 4:24.2.7-0ubuntu0.24.04.4
python3-wadllib 1.3.6-5
python3-wheel 0.42.0-2
python3-xmltodict 0.13.0-1ubuntu0.24.04.1
python3-yaml 6.0.1-2build2
python3.10 3.10.20-1+noble1
python3.10-dev 3.10.20-1+noble1
python3.10-distutils 3.10.20-1+noble1
python3.10-lib2to3 3.10.20-1+noble1
python3.10-minimal 3.10.20-1+noble1
python3.10-venv 3.10.20-1+noble1
python3.11 3.11.15-1+noble1
python3.11-dev 3.11.15-1+noble1
python3.11-distutils 3.11.15-1+noble1
python3.11-lib2to3 3.11.15-1+noble1
python3.11-minimal 3.11.15-1+noble1
python3.11-venv 3.11.15-1+noble1
python3.12 3.12.3-1ubuntu0.12
python3.12-dev 3.12.3-1ubuntu0.12
python3.12-minimal 3.12.3-1ubuntu0.12
python3.12-venv 3.12.3-1ubuntu0.12
python3.13 3.13.12-1+noble1
python3.13-dev 3.13.12-1+noble1
python3.13-venv 3.13.12-1+noble1
readline-common 8.2-4build1
redis-server 5:7.0.15-1ubuntu0.24.04.3
redis-tools 5:7.0.15-1ubuntu0.24.04.3
ripgrep 14.1.0-1
rpcsvc-proto 1.4.2-0ubuntu7
sed 4.9-2build1
sensible-utils 0.0.22
sgml-base 1.31
shared-mime-info 2.4-4
shtool 2.0.8-10
software-properties-common 0.99.49.4
ssl-cert 1.1.2ubuntu1
strace 6.8-0ubuntu2
sudo 1.9.15p5-3ubuntu5.24.04.2
systemd 255.4-1ubuntu8.14
systemd-dev 255.4-1ubuntu8.14
systemd-sysv 255.4-1ubuntu8.14
sysvinit-utils 3.08-6ubuntu3
tar 1.35+dfsg-3build1
tmux 3.4-1ubuntu0.1
tzdata 2025b-0ubuntu0.24.04.1
ubuntu-keyring 2023.11.28.1
ubuntu-mono 24.04-0ubuntu1
ucf 3.0043+nmu1
unminimize 0.2.1
uno-libs-private 4:24.2.7-0ubuntu0.24.04.4
unzip 6.0-28ubuntu4.1
ure 4:24.2.7-0ubuntu0.24.04.4
util-linux 2.39.3-9ubuntu6.5
uuid-dev:amd64 2.39.3-9ubuntu6.5
valgrind 1:3.22.0-0ubuntu3
vim 2:9.1.0016-1ubuntu7.10
vim-common 2:9.1.0016-1ubuntu7.10
vim-runtime 2:9.1.0016-1ubuntu7.10
wget 1.21.4-1ubuntu4.1
x11-common 1:7.7+23ubuntu3
x11-xkb-utils 7.7+8build2
x11proto-core-dev 2023.2-1
x11proto-dev 2023.2-1
xauth 1:1.1.2-1build1
xfonts-cyrillic 1:1.0.5+nmu1
xfonts-encodings 1:1.0.5-0ubuntu2
xfonts-scalable 1:1.0.3-1.3
xfonts-utils 1:7.7+6build3
xkb-data 2.41-2ubuntu1.1
xml-core 0.19
xorg-sgml-doctools 1:1.11-1.1
xserver-common 2:21.1.12-1ubuntu1.5
xtrans-dev 1.4.0-1
xvfb 2:21.1.12-1ubuntu1.5
xz-utils 5.6.1+really5.4.5-1ubuntu0.2
yq 3.1.0-3
zip 3.0-13ubuntu0.2
zlib1g-dev:amd64 1:1.3.dfsg-3.1ubuntu2.1
zlib1g:amd64 1:1.3.dfsg-3.1ubuntu2.1
```

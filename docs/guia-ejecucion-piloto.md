# Guia de ejecucion piloto de Caracoders Workstation

Esta guia esta pensada para una persona que va a probar `caracoders-workstation` en una maquina Ubuntu limpia o casi limpia antes de adoptarlo en mas equipos. No reemplaza al `README.md`: el README sigue siendo la puerta de entrada. Usa este documento para entender el panorama, preparar datos, ejecutar con menos sorpresa y anotar hallazgos del piloto.

## Resumen ejecutivo

`caracoders-workstation` es el estandar publico de estacion de trabajo Ubuntu para Caracoders Pro Services C.A. Su objetivo es preparar maquinas de desarrollo y soporte con una base repetible, auditable y conservadora.

El problema que resuelve es practico: evita que cada tecnico o desarrollador arme su laptop a mano, con versiones y configuraciones distintas. El repositorio define perfiles, paquetes, configuraciones y validaciones para que una maquina nueva quede lista para trabajar con Git, Docker, VS Code, OpenCode, herramientas de soporte, seguridad y desarrollo Laravel segun el perfil elegido.

La idea central no es instalar todos los runtimes de cada proyecto en el host. El host queda limpio y util. Los proyectos viven en Docker Compose y Dev Containers, con sus propias versiones, servicios, puertos y dependencias.

## Modelo mental

Piensa en dos capas:

| Capa | Que contiene | Quien decide versiones y servicios |
|---|---|---|
| Host Ubuntu | CLI base, Git, Docker Engine, VS Code, OpenCode, herramientas de soporte/seguridad, configuracion de shell | `caracoders-workstation` mediante perfiles y versiones aprobadas |
| Proyecto | App, PHP/Node del proyecto, PostgreSQL, Redis, Mailpit, pgAdmin, Dev Container, puertos | El repositorio del proyecto mediante Dockerfile, Compose, `.env` y Dev Container |

Esto permite que el equipo tenga una maquina base comun sin mezclar todos los servicios de todos los proyectos directamente en Ubuntu.

## Perfiles disponibles

La fuente de verdad de los perfiles esta en `config/profiles/*.env`. La composicion actual es:

| Perfil | Que instala o activa | Para quien sirve | Cuando usarlo | Riesgos o consideraciones |
|---|---|---|---|---|
| `minimal` | Modulo `minimal`: base CLI desde `packages/apt-base.txt`, incluyendo `curl`, `wget`, `git`, certificados, `gnupg`, compresores, `build-essential`, `jq`, `tree` y `htop`. | Cualquier maquina que solo necesita una base comun. | Primer smoke test, maquinas muy limitadas o validacion inicial. | No deja lista una estacion completa de desarrollo; faltan Docker, VS Code, OpenCode, Laravel y herramientas avanzadas. |
| `dev` | `minimal dev dotfiles`: herramientas de desarrollo como GitHub CLI, `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `btop`, `ncdu`, `make`, `shellcheck`, `shfmt`, `pre-commit`, `httpie`, Python, `pipx`, `yq`; instala Node/NVM y puede modificar `.bashrc` y Git global si das consentimiento. | Desarrolladores generales o tecnicos que necesitan tooling moderno sin instalar stack Laravel completo. | Cuando la maquina va a trabajar con repos, scripts y tooling CLI. | El bloque de `.bashrc` y la identidad Git global son cambios sensibles; revisar antes de aprobar. |
| `laravel` | `minimal laravel dotfiles`: PHP CLI y extensiones, Composer, Laravel Installer, Node/NVM, `pnpm`, cliente PostgreSQL y herramientas Redis. | Desarrolladores Laravel. | Cuando se necesita crear o mantener proyectos Laravel, especialmente con plantillas Docker/Dev Container del repo. | No instala servidores globales PostgreSQL, Redis, Apache, Nginx ni PHP-FPM; esos servicios deben vivir en contenedores del proyecto. |
| `docker` | `minimal docker`: Docker Engine desde el repositorio APT oficial de Docker, Compose plugin y prueba `hello-world` con imagen pineada por digest. | Maquinas que solo necesitan contenedores. | Si ya se trabaja con Docker Compose o Dev Containers, o si quieres validar Docker separado del resto. | Agregar el repo APT oficial y agregar el usuario al grupo `docker` requieren consentimiento. El grupo `docker` da privilegios locales altos y exige cerrar sesion/iniciar sesion para aplicar. |
| `devcontainer` | `minimal docker devcontainer`: Docker mas el estandar de runtime por plantillas del repositorio. El modulo `devcontainer` no instala nada extra en host por si mismo. | Equipos que quieren que el runtime de proyectos este declarado en Dev Containers. | Cuando la maquina debe abrir proyectos con Dev Containers y ya se acepta Docker como base. | Requiere Docker funcional. Para experiencia completa normalmente tambien conviene VS Code con extension de Dev Containers. |
| `vscode` | `minimal vscode`: instala VS Code desde el repo APT de Microsoft, puede instalar extensiones recomendadas y copiar `settings.json` global con backup. | Usuarios que trabajaran con VS Code. | Cuando se quiere una configuracion de editor estandarizada. | Agregar el repo APT de Microsoft y copiar configuracion global requieren consentimiento. Las extensiones se instalan si `INSTALL_VSCODE_EXTENSIONS=true`. |
| `ai` | `minimal dev ai`: instala prerequisitos de desarrollo, Node/NVM, OpenCode y MCP v1. Instala paquetes npm globales pineados: OpenCode, filesystem MCP, Playwright MCP, Context7 MCP y PostgreSQL MCP. | Usuarios que usaran flujo AI/OpenCode en host. | Cuando solo quieres probar OpenCode/MCP o preparar una estacion AI sin Laravel/Docker completo. | La configuracion MCP filesystem debe estar muy acotada. No uses `$HOME` completo salvo que entiendas el riesgo y lo apruebes explicitamente. No se copian claves de API; debes configurarlas fuera del repo. |
| `support` | `minimal support`: diagnostico y soporte, incluyendo DNS/whois/traceroute, red, `iperf3`, `httpie`, Remmina, Flameshot, smartmontools, Disks, `ncdu`, `lsof`, `rsync`, FileZilla. | Tecnico de soporte IT. | Cuando la maquina es para diagnostico, acceso remoto y soporte operativo. | AnyDesk esta gated por consentimiento, pero la instalacion esta intencionalmente no implementada en v1; si se aprueba, solo avisa que falta un instalador revisado. |
| `security` | `minimal dev security`: herramientas base de desarrollo, `shellcheck`, `shfmt`, `pre-commit`, mas instalacion local de Gitleaks, Trivy y Hadolint con versiones/checksums controlados. | Mantenedores, revisores y CI/security checks locales. | Antes de liberar cambios, auditar secretos, Dockerfiles y templates. | Descarga binarios de seguridad versionados y verifica SHA256; puede reemplazar binarios existentes por la version aprobada. |
| `full` | `minimal dev laravel docker devcontainer vscode ai support security starship dotfiles`: estacion Caracoders completa. | Desarrollador/soporte Caracoders estandar. | Piloto principal en 1 o 2 maquinas representativas. | Es el perfil con mas cambios: APT, Docker, VS Code, npm global, OpenCode, MCP, Starship, fuente Nerd Font, `.bashrc`, Git global y configuraciones con backup segun consentimientos. Ejecuta primero dry-run. |

## Comandos principales

| Comando | Para que sirve | Cuando ejecutarlo |
|---|---|---|
| `./verify.sh --profile full` | Valida el repositorio: estructura requerida, sintaxis Bash, patrones inseguros, parser de config, perfiles, MCP gates, JSON/TOML/YAML, pinning de imagenes y paquetes, hardening de CI. | Antes o despues de instalar para asegurar que el checkout local no esta roto. No valida que tu maquina tenga todas las herramientas instaladas. |
| `./bootstrap.sh --profile full --dry-run` | Muestra acciones planeadas sin cambiar el sistema. En dry-run tambien muestra donde pediria confirmaciones sensibles. | Siempre primero en Ubuntu fresh o antes de un piloto. |
| `./bootstrap.sh --profile full` | Ejecuta el flujo real del perfil seleccionado. Puede pedir confirmaciones interactivas. | Despues de revisar el dry-run y tener datos/consentimientos listos. |
| `./bootstrap.sh --profile full --yes --config ./.caracoders-workstation.env` | Ejecuta en modo no interactivo usando una config local ignorada por Git. Las acciones sensibles solo se hacen si la variable de consentimiento correspondiente esta en `true`. | Pilotos repetibles, instalacion asistida o maquinas donde ya decidiste politicas. |
| `./doctor.sh --profile full --strict` | Revisa el estado real de la maquina para el perfil: comandos requeridos y warnings como Docker instalado pero no accesible. En `--strict` falla si falta algo o queda algun warning. | Despues de activar la integracion de shell y refrescar el grupo Docker si aplica. |
| `./update.sh --profile full` | Opcionalmente hace `git pull --ff-only` si el repo es un checkout Git y luego vuelve a ejecutar `bootstrap.sh` para el perfil. | Para actualizar una workstation ya instalada con una nueva version del repo. |

## Activacion post-install

Despues de `./bootstrap.sh --profile full`, no concluyas que fallaron `node`, `npm`, `pnpm`, `opencode` o `laravel` solo porque no aparecen en la misma terminal. Primero activa la integracion de shell:

```bash
source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"
```

Abrir una terminal nueva tambien carga la integracion si aprobaste el bloque de `.bashrc`.

Si Docker cambio el grupo del usuario o `docker info` no funciona sin `sudo`, ejecuta `newgrp docker`; si no aplica o sigue fallando, cierra sesion/inicia sesion o reinicia. Si Docker aun no responde, arranca el daemon con `sudo systemctl enable --now docker`.

Orden recomendado despues de activar la terminal y Docker:

```bash
./doctor.sh --profile full --strict
./verify.sh --profile full
```

`doctor.sh` valida la maquina host. `verify.sh` valida el checkout del repo, politicas, pines y templates.

## Flujo recomendado para Ubuntu fresh

1. Confirma version de Ubuntu. El objetivo principal del repo es Ubuntu 26.04 LTS; Ubuntu 24.04 LTS es secundario si los paquetes estan disponibles.
2. Instala lo minimo para clonar si hace falta: Git y certificados suelen venir o se instalan manualmente segun la imagen base.
3. Clona el repo remoto:

```bash
git clone https://github.com/MarcoVegaR/caracoders-workstation caracoders-workstation
cd caracoders-workstation
```

4. Lee `README.md`, `docs/profiles.md`, `docs/install-flow.md`, `docs/pilot-plan.md` y esta guia.
5. Ejecuta validacion del repo:

```bash
./verify.sh --profile full
```

6. Ejecuta dry-run:

```bash
./bootstrap.sh --profile full --dry-run
```

7. Si usaras modo silencioso, prepara config local:

```bash
cp .caracoders-workstation.env.example .caracoders-workstation.env
nano .caracoders-workstation.env
```

8. Ejecuta instalacion real interactiva o silenciosa:

```bash
./bootstrap.sh --profile full
```

O:

```bash
./bootstrap.sh --profile full --yes --config ./.caracoders-workstation.env
```

9. Activa la integracion post-install en la terminal actual o abre una nueva terminal:

```bash
source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"
```

10. Si Docker agrego tu usuario al grupo `docker` o Docker no es accesible sin `sudo`, ejecuta `newgrp docker`; si no aplica o sigue fallando, cierra sesion/inicia sesion o reinicia. Si el daemon sigue sin responder, usa `sudo systemctl enable --now docker`.
11. Valida la maquina y luego el repo:

```bash
./doctor.sh --profile full --strict
./verify.sh --profile full
```

12. Prueba un caso real: abrir VS Code, correr Docker, crear o abrir un proyecto Laravel con template, y validar OpenCode/MCP solo con rutas permitidas.

## Que pasa con `./bootstrap.sh --profile full`

El flujo real esta en `scripts/bootstrap.sh`. Para `full`, la secuencia efectiva es:

1. Carga argumentos, versiones y config local si pasaste `--config`.
2. Verifica que el perfil exista.
3. Ejecuta `preflight.sh`.
4. Ejecuta `install-apt.sh`, que instala paquetes APT segun los modulos del perfil: base, dev, laravel, support, security y docker donde aplique.
5. Recorre los modulos de `full`: `minimal`, `dev`, `laravel`, `docker`, `devcontainer`, `vscode`, `ai`, `support`, `security`, `starship`, `dotfiles`.
6. Para `dev`, instala Node/NVM y aplica dotfiles.
7. Para `laravel`, instala Node/NVM, PHP/Composer, Laravel Installer y dotfiles.
8. Para `docker`, instala o valida Docker y Compose, ejecuta un smoke test y puede agregar el usuario al grupo Docker.
9. Para `devcontainer`, solo informa que las plantillas son assets del repo; no instala host extra fuera de Docker/VS Code.
10. Para `vscode`, instala VS Code si falta, lista extensiones recomendadas, puede instalarlas y copiar configuracion global.
11. Para `ai`, instala Node/NVM si hace falta, OpenCode y MCP.
12. Para `support`, instala herramientas de soporte.
13. Para `security`, instala herramientas de seguridad y scanners aprobados.
14. Para `starship`, instala Starship, copia config y opcionalmente instala FiraCode Nerd Font.
15. Para `dotfiles`, aplica el bloque reversible de Bash y, si hay datos, Git global.
16. Ejecuta `doctor.sh --profile full` para revisar el estado del host.
17. Ejecuta `verify.sh --profile full` para revisar politicas, pines y templates del repo.
18. Termina avisando como activar la integracion de shell, refrescar grupo Docker y repetir `doctor --strict`/`verify`.

El instalador es conservador e idempotente: si una herramienta ya existe, varios modulos la detectan y evitan reinstalarla. Aun asi, algunos componentes de seguridad y configuracion pueden reinstalar o copiar versiones aprobadas con backup.

## Donde es interactivo y donde no

Sin `--yes`, el instalador pregunta antes de acciones sensibles. Si respondes que no, esa parte se salta o falla de forma segura segun el caso.

Con `--yes`, no pregunta. Pero `--yes` no significa aprobar todo: las acciones sensibles solo se ejecutan si la variable correspondiente en `.caracoders-workstation.env` esta en `true`.

Con `--dry-run`, no modifica el sistema. En modo dry-run normal indica que en runtime habria confirmaciones. En `--dry-run --yes --config ...`, muestra si cada accion sensible seria aprobada o saltada segun la config.

Acciones sensibles principales:

| Accion | Variable de consentimiento |
|---|---|
| Agregar repo APT oficial de Docker e instalar Docker Engine | `CARACODERS_ALLOW_DOCKER_APT_REPO` |
| Agregar usuario actual al grupo `docker` | `CARACODERS_CONFIRM_DOCKER_GROUP` |
| Agregar repo APT de Microsoft e instalar VS Code | `CARACODERS_ALLOW_VSCODE_APT_REPO` |
| Copiar configuracion global de VS Code | `CARACODERS_CONFIRM_COPY_VSCODE_CONFIG` |
| Modificar `.bashrc` con bloque marcado de Caracoders | `CARACODERS_CONFIRM_BASHRC_BLOCK` |
| Configurar `git config --global user.name/user.email` | `CARACODERS_CONFIRM_GITCONFIG` |
| Copiar configuracion global de OpenCode a `~/.config/opencode` | `CARACODERS_CONFIRM_OPENCODE_CONFIG` |
| Permitir MCP filesystem sobre todo HOME, `/` o padres de HOME | `CARACODERS_CONFIRM_MCP_HOME_ACCESS` |
| Permitir MCP filesystem fuera de HOME | `CARACODERS_CONFIRM_MCP_OUTSIDE_HOME_ACCESS` |
| Instalar Starship pineado | `CARACODERS_CONFIRM_STARSHIP_INSTALL` |
| Instalar FiraCode Nerd Font | `CARACODERS_CONFIRM_STARSHIP_FONT` |
| Intentar flujo AnyDesk | `CARACODERS_CONFIRM_ANYDESK` |
| Sobrescribir archivos existentes con backup | `CARACODERS_CONFIRM_OVERWRITE_EXISTING` |

## Datos y configuracion a preparar

Copia `.caracoders-workstation.env.example` a `.caracoders-workstation.env`. Ese archivo local no debe subirse a Git. El parser lo lee como datos `KEY=VALUE`, no como Bash ejecutable. Rechaza claves peligrosas como `PATH`, `IFS`, `BASH_ENV`, `SHELLOPTS`, claves internas `CW_*`, sustitucion de comandos, backticks y punto y coma.

Variables utiles:

| Variable | Para que sirve | Recomendacion para piloto |
|---|---|---|
| `CARACODERS_USER_NAME`, `CARACODERS_USER_EMAIL` | Identidad del usuario Caracoders. | Completar con datos reales no secretos. |
| `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL` | Identidad que puede configurarse en Git global si apruebas. | Completar solo si quieres que el instalador configure Git global. |
| `GITHUB_USERNAME` | Usuario GitHub. | Completar para documentar contexto local; no es secreto. |
| `OPENCODE_PROVIDER` | Proveedor esperado para OpenCode. | Ejemplo: `openai`; revisar politica del equipo. |
| `OPENCODE_API_KEY` | Clave de API. | No pongas secretos reales si no es estrictamente necesario; preferir mecanismos seguros fuera del repo. Nunca commitear este archivo. |
| `MCP_FILESYSTEM_ALLOW_HOME` | Solicita acceso amplio del MCP filesystem a HOME. | Mantener `false` salvo caso excepcional aprobado. |
| `MCP_FILESYSTEM_ALLOWED_PATHS` | Rutas separadas por coma que el MCP filesystem podra ver. | Usar rutas acotadas, por ejemplo `$HOME/projects,$HOME/caracoders`. No uses `$HOME` entero sin entenderlo. |
| `INSTALL_VSCODE_EXTENSIONS` | Controla instalacion de extensiones recomendadas. | `true` para full; `false` si quieres revisar extensiones manualmente. |
| `INSTALL_STARSHIP_FONT` | Controla instalacion de fuente Nerd Font. | `true` si usaras Starship visualmente; `false` en servidores o VM simple. |
| `CARACODERS_ALLOW_*`, `CARACODERS_CONFIRM_*` | Consentimientos explicitos para modo `--yes`. | Poner `true` solo en acciones revisadas y aceptadas para esa maquina. |

No incluyas secretos reales en tickets, capturas ni reportes del piloto. Si debes probar una clave, rotala despues si hubo exposicion accidental.

## Casos practicos

### Tecnico de soporte IT

Usa `support` si la maquina se dedicara a diagnostico y soporte:

```bash
./bootstrap.sh --profile support --dry-run
./bootstrap.sh --profile support
./doctor.sh --profile support --strict
```

Obtendras herramientas de red, acceso remoto grafico, captura de pantalla, discos, espacio, procesos y transferencia. No incluye tooling ofensivo ni shell MCP.

### Desarrollador Laravel

Usa `full` si tambien necesitas Docker, VS Code, OpenCode y seguridad. Usa `laravel` si solo quieres productividad Laravel en host:

```bash
./bootstrap.sh --profile laravel --dry-run
./bootstrap.sh --profile laravel
./doctor.sh --profile laravel --strict
```

Recuerda: PostgreSQL, Redis, Mailpit y runtime del proyecto deben ir en Docker Compose/Dev Container del proyecto, no como servicios globales en Ubuntu.

### Maquina con Docker ya instalado

Puedes ejecutar `docker` o `full`. El instalador detecta si `docker` ya existe y valida version/Compose/smoke test. Si el daemon no es accesible para tu usuario, `doctor.sh` lo avisara. Si apruebas agregar el usuario al grupo `docker`, ejecuta `newgrp docker` o cierra sesion/inicia sesion antes de validar otra vez.

### Piloto en 1-2 maquinas

Usa una maquina limpia y, si es posible, una maquina existente representativa. En ambas:

```bash
./bootstrap.sh --profile full --dry-run
./bootstrap.sh --profile full
source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"
newgrp docker
./doctor.sh --profile full --strict
./verify.sh --profile full
```

Registra tiempo de instalacion, prompts, fallas, workarounds, diferencias entre maquinas y si el flujo es entendible para alguien que no escribio el repo.

### Solo AI/OpenCode

Usa `ai`:

```bash
./bootstrap.sh --profile ai --dry-run
./bootstrap.sh --profile ai
./doctor.sh --profile ai --strict
```

Prepara antes `MCP_FILESYSTEM_ALLOWED_PATHS` con rutas especificas. Evita `$HOME` completo. OpenCode/MCP requieren Node/npm; el perfil `ai` incluye `minimal dev ai`, por eso trae prerequisitos.

### Solo validacion o dry-run

Si no quieres cambiar el sistema:

```bash
./verify.sh --profile full
./bootstrap.sh --profile full --dry-run
./doctor.sh --profile full
```

`verify.sh` valida el repo. `bootstrap --dry-run` muestra intenciones. `doctor.sh` muestra que comandos faltan actualmente en la maquina sin instalar nada.

## Como anotar hallazgos durante el piloto

Usa una nota por maquina con este formato minimo:

```markdown
# Piloto caracoders-workstation

- Maquina:
- Ubuntu:
- Fecha:
- Perfil:
- Commit o tag probado:
- Modo: interactivo / --yes --config / dry-run
- Tiempo total:

## Antes
- Estado inicial de Docker/VS Code/Node/PHP:
- Restricciones de red/proxy/VPN:

## Durante
- Prompts que aparecieron:
- Consentimientos aprobados:
- Consentimientos rechazados:
- Errores o warnings:
- Comandos que se repitieron:

## Despues
- Resultado de doctor:
- Resultado de verify:
- Prueba Docker:
- Prueba VS Code/Dev Container:
- Prueba OpenCode/MCP:
- Pendientes:
```

Si falla algo, copia el comando exacto, las ultimas lineas del error y si estabas en `--dry-run`, interactivo o `--yes`.

## Que hacer si algo falla

1. No sigas con rollout masivo.
2. Relee el primer error real; no te quedes solo con el ultimo mensaje.
3. Ejecuta `./doctor.sh --profile <perfil>` para ver comandos faltantes.
4. Ejecuta `./verify.sh --profile <perfil>` desde la raiz del repo para descartar problemas del checkout.
5. Si el error es Docker permission denied, ejecuta `newgrp docker` o cierra sesion/inicia sesion si se cambio el grupo `docker`; si el daemon no responde, usa `sudo systemctl enable --now docker`.
6. Si npm no aparece, revisa NVM con `./scripts/install-node-nvm.sh --profile dev` y luego `./doctor.sh --profile ai --strict`.
7. Si MCP falla por rutas, usa rutas acotadas bajo `$HOME/projects` o `$HOME/caracoders`; no fuerces `$HOME` completo salvo aprobacion consciente.
8. Si `node`, `npm`, `pnpm`, `opencode` o `laravel` no aparecen en la misma terminal, ejecuta `source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"` o abre una terminal nueva antes de declarar fallo.
9. Si una config global existente bloquea copia, decide si aceptas backup/sobrescritura con `CARACODERS_CONFIRM_OVERWRITE_EXISTING=true` o si prefieres revisar manualmente.
10. Documenta el hallazgo con maquina, perfil, comando, error y workaround.

## Checklist antes, durante y despues

Antes:

- Confirmar Ubuntu 26.04 LTS o 24.04 LTS compatible.
- Confirmar conectividad a GitHub, repos APT, npm y descargas necesarias.
- Clonar `https://github.com/MarcoVegaR/caracoders-workstation`.
- Revisar `README.md`, `docs/profiles.md`, `docs/install-flow.md` y esta guia.
- Ejecutar `./verify.sh --profile full`.
- Ejecutar `./bootstrap.sh --profile full --dry-run`.
- Preparar `.caracoders-workstation.env` si usaras `--yes`.
- Definir rutas MCP acotadas; no usar `$HOME` entero por comodidad.

Durante:

- Leer cada prompt antes de responder.
- Aprobar solo repos APT, grupo Docker, VS Code config, OpenCode config, Starship, fuente y dotfiles si tienen sentido para esa maquina.
- Anotar prompts, tiempos, errores y decisiones.
- No pegar secretos en terminal compartida, tickets o capturas.

Despues:

- Ejecutar `source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"` o abrir una terminal nueva.
- Ejecutar `newgrp docker` si se cambio el grupo Docker; si no aplica o sigue fallando, cerrar sesion/iniciar sesion o reiniciar.
- Ejecutar `./doctor.sh --profile full --strict`.
- Ejecutar `./verify.sh --profile full`.
- Probar Docker Compose o al menos `docker compose version`.
- Abrir VS Code si se instalo.
- Revisar `~/.config/opencode` si se copio configuracion.
- Confirmar que `.caracoders-workstation.env` no aparece en `git status` para commit.
- Registrar hallazgos y decision: aprobar, corregir o repetir piloto.

## Advertencias importantes

- Ejecuta primero `./bootstrap.sh --profile full --dry-run`.
- No uses `$HOME` completo para MCP filesystem sin entender que aumenta mucho el alcance de lectura/escritura disponible para herramientas AI.
- Si aceptas agregar tu usuario al grupo `docker`, ejecuta `newgrp docker` o reinicia sesion antes de concluir que Docker falla.
- Si instalaste dotfiles y una herramienta no aparece en la misma terminal, carga `source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"` o abre una terminal nueva.
- No subas `.caracoders-workstation.env`; puede contener datos personales, rutas internas o secretos.
- `--yes` no aprueba acciones sensibles por si solo; requiere consentimientos `CARACODERS_*="true"`.
- El perfil `full` es ideal para el piloto principal, pero no es obligatorio para maquinas con proposito limitado.
- El rollback completo de paquetes/repos/configs es deliberadamente conservador; `rollback-dotfiles.sh` ayuda con el bloque Bash, pero no esperes un desinstalador destructivo automatico.

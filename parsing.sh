#!/usr/bin/env bash

################################################################################
# Titulo    : Parsing HTML (refatorado)                                        #
# Versao    : 2.3                                                              #
# -----------------------------------------------------------------------------#
# Descrição:                                                                   #
#   Ferramenta em Bash para:                                                   #
#     - Extrair links de páginas HTML (href / action)                          #
#     - Extrair hosts/dominios a partir desses links                           #
#     - Verificar hosts vivos via DNS                                          #
#     - (Opcional) Exportar hosts vivos para arquivo (-o)                      #
#     - (Opcional) Saída em JSON (--json [arquivo])                            #
#     - (Opcional) Modo silencioso (--silent)                                  #
#     - (Opcional) Crawling simples de URLs internas (--crawl)                 #
#     - (Opcional) Mapear comentários HTML (--comments)                        #
################################################################################

# ==============================================================================
# Constantes de cor
# ==============================================================================

RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
CYAN='\033[36;1m'
RED_BLINK='\033[31;5;1m'
END='\033[m'

VERSION='2.3'

# Diretório onde o usuário estava ao chamar o script
ORIG_PWD="$(pwd)"

# Diretório temporário global
TMPDIR=""

# Flags e opções
URL=""
INPUT_FILE=""
OUTPUT_FILE=""
SILENT=0
JSON=0
JSON_FILE=""
CRAWL=0
COMMENTS=0   # <- novo: flag para exibir comentários HTML

# Arrays para saída estruturada
declare -a JSON_ENTRIES=()
declare -a OUTPUT_HOSTS=()

# Trap para Ctrl+C
trap __Ctrl_c__ INT

# ==============================================================================
# Funções utilitárias
# ==============================================================================

log_info() {
    [[ "$SILENT" -eq 0 ]] && echo -e "$@"
}

log_error() {
    echo -e "$@" >&2
}

__Ctrl_c__() {
    __Clear__
    echo -e "\n${RED_BLINK}!!! Ação abortada !!!${END}\n"
    exit 1
}

__Banner__() {
    cat <<EOF

        ${YELLOW}
        ################################################################################
        #                                                                              #
        #                             PARSING HTML                                     #
        #                            Script em Bash                                    #
        #                             Version ${VERSION}                                      #
        #                                                                              #
        ################################################################################
        ${END}

        Uso     : ${GREEN}${0}${END} [OPÇÕES] [URL]
        Exemplo : ${GREEN}${0}${END} https://www.site.com

        Tente ${GREEN}${0} -h${END} para mais opções.
EOF
}

__Help__() {
    cat <<EOF

NAME
    ${0} - Ferramenta em Bash para procura de links/hosts em páginas web.

SYNOPSIS
    ${0} [OPÇÕES] [URL]

DESCRIÇÃO
    Dada uma URL ou arquivo HTML, o script:
      - Extrai links (href / action)
      - Extrai hosts a partir desses links
      - Verifica hosts vivos via DNS
      - Pode exportar hosts vivos para arquivo
      - Pode gerar saída em JSON
      - Pode mapear comentários HTML (<!-- ... -->)

OPÇÕES
    -h, --help
        Mostra este menu de ajuda.

    -v, --version
        Mostra a versão do programa.

    -f, --file <arquivo>
        Usa um arquivo local (HTML/texto) como fonte em vez de URL.

    -o, --output <arquivo>
        Exporta APENAS os hosts vivos para o arquivo informado (um por linha).
        Ex: ${0} -o vivos.txt https://alvo.com

    --silent
        Modo silencioso: reduz a quantidade de mensagens no terminal.
        Útil para pipelines/scripting.

    --json [arquivo]
        Gera saída em JSON com informações de cada host:
            host, status, IPs.
        Se você informar um arquivo, o JSON será salvo nele:
            Ex: ${0} --json resultado.json https://alvo.com
        Se não informar arquivo, o JSON é impresso em stdout:
            Ex: ${0} --json https://alvo.com

    --crawl
        Ativa crawling simples:
          - Identifica URLs internas (mesmo host base) encontradas nos links
          - Salva essas URLs em um arquivo 'crawl_urls.txt' no diretório temporário
        (pensado para integração com pipelines de brute force + screenshots).

    -c, --comments
        Mapeia comentários HTML (blocos <!-- ... -->) encontrados na página
        e exibe uma seção com o conteúdo desses comentários.

ARGUMENTOS
    URL
        Se você passar apenas uma URL (sem -f), o script fará o download da
        página e realizará toda a análise a partir dela.

EOF
}

# Verifica dependências via PATH
__Require__() {
    local bin
    for bin in "$@"; do
        if ! command -v "$bin" >/dev/null 2>&1; then
            log_error "${RED}[-] Dependência ausente:${END} ${bin}"
            exit 1
        fi
    done
}

# Cria diretório temporário seguro
__MakeTmpDir__() {
    TMPDIR="$(mktemp -d /tmp/parsinghtml.XXXXXX)" || {
        log_error "${RED}[-] Falha ao criar diretório temporário.${END}"
        exit 1
    }
}

# Limpa diretório temporário
__Clear__() {
    if [[ -n "$TMPDIR" ]]; then
        rm -rf "$TMPDIR" 2>/dev/null
        TMPDIR=""
    fi
}

# ==============================================================================
# Parsing de argumentos de linha de comando
# ==============================================================================

__ParseArgs__() {
    if [[ $# -eq 0 ]]; then
        __Banner__
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                __Help__
                exit 0
            ;;
            -v|--version)
                echo -e "Version: ${VERSION}"
                exit 0
            ;;
            -f|--file)
                if [[ -z "${2:-}" ]]; then
                    log_error "${RED}[-] Opção -f requer um arquivo.${END}"
                    exit 1
                fi
                INPUT_FILE="$2"
                shift 2
            ;;
            -o|--output)
                if [[ -z "${2:-}" ]]; then
                    log_error "${RED}[-] Opção -o requer um arquivo de saída.${END}"
                    exit 1
                fi
                OUTPUT_FILE="$2"
                shift 2
            ;;
            --silent)
                SILENT=1
                shift
            ;;
            --json)
                JSON=1
                # Se o próximo argumento existir e NÃO começar com '-', vamos tratar como arquivo
                if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                    JSON_FILE="$2"
                    shift 2
                else
                    shift
                fi
            ;;
            --crawl)
                CRAWL=1
                shift
            ;;
            -c|--comments)
                COMMENTS=1
                shift
            ;;
            -*)
                log_error "${RED}[-] Opção desconhecida:${END} $1"
                exit 1
            ;;
            *)
                if [[ -z "$URL" ]]; then
                    URL="$1"
                    shift
                else
                    log_error "${RED}[-] Argumento inesperado:${END} $1"
                    exit 1
                fi
            ;;
        esac
    done

    if [[ -z "$URL" && -z "$INPUT_FILE" ]]; then
        log_error "${RED}[-] Necessário informar uma URL ou usar -f <arquivo>.${END}"
        exit 1
    fi
}

# Verificação inicial
__Verification__() {
    __Require__ wget host grep sed awk sort
    [[ -z "$TMPDIR" ]] && __MakeTmpDir__
}

# ==============================================================================
# Download da página
# ==============================================================================

__Download__() {
    cd "$TMPDIR" || exit 1

    log_info "\n${GREEN}[+] Download do site...${END}\n"
    if wget -q -c --show-progress "${URL}" -O FILE; then
        log_info "\n${GREEN}[+] Download completo!${END}\n"
    else
        log_error "\n${RED}[-] Falha no download de: ${URL}${END}\n"
        exit 1
    fi
}

# ==============================================================================
# Abrindo arquivo com -f
# ==============================================================================

__OpenFile__() {
    if [[ ! -e "${INPUT_FILE}" ]]; then
        log_error "\n${RED}[-] Arquivo não encontrado:${END} ${INPUT_FILE}\n"
        exit 1
    fi

    cp "${INPUT_FILE}" "$TMPDIR/FILE"
    cd "$TMPDIR" || exit 1
}

# ==============================================================================
# Filtrando links
# ==============================================================================

__FindLinks__() {
    log_info "${CYAN}[+] Extraindo links da página...${END}\n"

    grep -Eo '(href|action)=("[^"]*"|'\''[^'\'']*'\'')' FILE 2>/dev/null > .links_attr || true
    grep -Eo '"[^"]*"|'\''[^'\'']*'\''' .links_attr 2>/dev/null > .links_quoted || true
    sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" .links_quoted > .links_clean 2>/dev/null || true
    grep '\.' .links_clean 2>/dev/null | sort -u > links || touch links
}

# ==============================================================================
# Filtrando hosts
# ==============================================================================

__FindHosts__() {
    log_info "${CYAN}[+] Extraindo hosts a partir dos links...${END}\n"

    grep -Eo 'https?://[^/" ]+' links 2>/dev/null | sed -E 's#https?://##' > .hosts_raw1 || true
    grep -Eo '([a-zA-Z0-9._-]+\.[a-zA-Z]{2,})' links 2>/dev/null >> .hosts_raw1 || true

    sort -u .hosts_raw1 > hosts 2>/dev/null || touch hosts
}

# ==============================================================================
# Crawling simples (URLs internas)
# ==============================================================================

__CrawlSimple__() {
    [[ "$CRAWL" -eq 1 ]] || return
    [[ -z "$URL" ]] && return

    local base_host
    base_host="$(echo "$URL" | awk -F/ '{print $3}')"

    log_info "${CYAN}[+] Crawling simples habilitado (URLs internas de: ${base_host})${END}\n"

    local url
    : > crawl_urls.txt

    while read -r url; do
        [[ -z "$url" ]] && continue
        case "$url" in
            http://*|https://*)
                local host_part
                host_part="$(echo "$url" | awk -F/ '{print $3}')"
                [[ "$host_part" == "$base_host" ]] && echo "$url" >> crawl_urls.txt
            ;;
        esac
    done < links

    if [[ -s crawl_urls.txt ]]; then
        sort -u crawl_urls.txt -o crawl_urls.txt
        log_info "${GREEN}[+] URLs internas salvas em:${END} $TMPDIR/crawl_urls.txt\n"
    else
        log_info "${YELLOW}[i] Nenhuma URL interna encontrada para crawling simples.${END}\n"
    fi
}

# ==============================================================================
# Mostrando links encontrados
# ==============================================================================

__ShowLinks__() {
    [[ "$SILENT" -eq 1 ]] && return

    echo -e "${YELLOW}
################################################################################
#                         Links encontrados                                    #
################################################################################
${END}"

    if [[ ! -s links ]]; then
        echo -e "${RED}[-] Nenhum link encontrado.${END}\n"
        return
    fi

    while read -r linha; do
        [[ -n "$linha" ]] && echo "$linha"
    done < links

    echo
}

# ==============================================================================
# Mostrando Hosts encontrados
# ==============================================================================

__ShowHosts__() {
    [[ "$SILENT" -eq 1 ]] && return

    echo -e "${YELLOW}
################################################################################
#                         Hosts encontrados                                    #
################################################################################
${END}"

    if [[ ! -s hosts ]]; then
        echo -e "${RED}[-] Nenhum host encontrado.${END}\n"
        return
    fi

    while read -r linha; do
        [[ -n "$linha" ]] && echo "$linha"
    done < hosts

    echo
}

# ==============================================================================
# Verificando e mostrando Hosts ativos
# ==============================================================================

__LiveHosts__() {
    [[ "$SILENT" -eq 1 ]] || echo -e "${YELLOW}
################################################################################
#                            Hosts ativos                                      #
################################################################################
${END}"

    if [[ ! -s hosts ]]; then
        log_info "${RED}[-] Nenhum host para testar.${END}\n"
        return
    fi

    while read -r linha; do
        [[ -z "$linha" ]] && continue

        local status="DEAD"
        local ipv4=""
        local ipv6=""

        if host "$linha" > .host_out 2>/dev/null; then
            ipv4="$(grep 'has address' .host_out | awk '{print $4}' | paste -sd ',' - 2>/dev/null)"
            ipv6="$(grep 'IPv6 address' .host_out | awk '{print $5}' | paste -sd ',' - 2>/dev/null)"

            if [[ -n "$ipv4" || -n "$ipv6" ]]; then
                status="LIVE"
            else
                status="RESOLVE"
            fi
        else
            status="DEAD"
        fi

        local ip_combined
        if [[ -n "$ipv4" && -n "$ipv6" ]]; then
            ip_combined="${ipv4},${ipv6}"
        else
            ip_combined="${ipv4}${ipv6}"
        fi

        if [[ "$SILENT" -eq 0 ]]; then
            case "$status" in
                LIVE)
                    echo -e "${GREEN}[LIVE]${END}   ${linha}\t${ip_combined}"
                ;;
                RESOLVE)
                    echo -e "${YELLOW}[RESOLVE]${END} ${linha}\t${ip_combined}"
                ;;
                DEAD)
                    echo -e "${RED}[DEAD]${END}    ${linha}"
                ;;
            esac
        fi

        JSON_ENTRIES+=("$(printf '{"host":"%s","status":"%s","ip":"%s"}' "$linha" "$status" "$ip_combined")")

        if [[ "$status" == "LIVE" || "$status" == "RESOLVE" ]]; then
            OUTPUT_HOSTS+=("$linha")
        fi

    done < hosts

    [[ "$SILENT" -eq 1 ]] || echo
}

# ==============================================================================
# Mapeando comentários HTML
# ==============================================================================

__FindComments__() {
    log_info "${CYAN}[+] Extraindo comentários HTML (<!-- ... -->)...${END}\n"

    : > comments

    awk '
        BEGIN { in_comment=0 }
        {
            line=$0

            # Início de comentário
            if (index(line, "<!--") > 0) {
                in_comment=1
            }

            if (in_comment) {
                print line >> "comments"
            }

            # Fim de comentário
            if (index(line, "-->") > 0 && in_comment) {
                in_comment=0
                print "" >> "comments"
            }
        }
    ' FILE 2>/dev/null || true

    if [[ ! -s comments ]]; then
        log_info "${YELLOW}[i] Nenhum comentário HTML encontrado.${END}\n"
    fi
}

__ShowComments__() {
    [[ "$SILENT" -eq 1 ]] && return
    [[ "$COMMENTS" -eq 1 ]] || return

    echo -e "${YELLOW}
################################################################################
#                       Comentários HTML encontrados                            #
################################################################################
${END}"

    if [[ ! -s comments ]]; then
        echo -e "${RED}[-] Nenhum comentário HTML encontrado.${END}\n"
        return
    fi

    cat comments
    echo
}

# ==============================================================================
# Exportando hosts vivos para arquivo (se -o/--output)
# ==============================================================================

__ExportLiveHosts__() {
    [[ -z "$OUTPUT_FILE" ]] && return

    if [[ "${#OUTPUT_HOSTS[@]}" -eq 0 ]]; then
        log_info "${YELLOW}[i] Nenhum host vivo para exportar.${END}"
        return
    fi

    printf "%s\n" "${OUTPUT_HOSTS[@]}" | sort -u > "${ORIG_PWD}/${OUTPUT_FILE}"
    log_info "${GREEN}[+] Hosts vivos exportados para:${END} ${ORIG_PWD}/${OUTPUT_FILE}"
}

# ==============================================================================
# Saída JSON (se --json)
# ==============================================================================

__OutputJson__() {
    [[ "$JSON" -eq 1 ]] || return

    local len="${#JSON_ENTRIES[@]}"

    # Monta JSON em string
    local json_output
    {
        echo "["
        local i
        for (( i=0; i<len; i++ )); do
            if (( i == len - 1 )); then
                echo "  ${JSON_ENTRIES[$i]}"
            else
                echo "  ${JSON_ENTRIES[$i]},"
            fi
        done
        echo "]"
    } > "${TMPDIR}/__json_tmp__.txt"

    if [[ -n "$JSON_FILE" ]]; then
        cp "${TMPDIR}/__json_tmp__.txt" "${ORIG_PWD}/${JSON_FILE}"
        log_info "${GREEN}[+] JSON exportado para:${END} ${ORIG_PWD}/${JSON_FILE}"
    else
        cat "${TMPDIR}/__json_tmp__.txt"
    fi
}

# ==============================================================================
# Mostrando quantidade de links, hosts e comentários encontrados
# ==============================================================================

__ShowResume__() {
    [[ "$SILENT" -eq 1 ]] && return

    local nlinks nhosts ncomments
    nlinks=$(wc -l < links 2>/dev/null || echo 0)
    nhosts=$(wc -l < hosts 2>/dev/null || echo 0)
    ncomments=$(wc -l < comments 2>/dev/null || echo 0)

    echo -e "
${YELLOW}================================================================================${END}
Found :
        Links      : ${CYAN}${nlinks}${END}
        Hosts      : ${CYAN}${nhosts}${END}
        Comentários: ${CYAN}${ncomments}${END}
${YELLOW}================================================================================${END}
"
}

# ==============================================================================
# Função principal
# ==============================================================================

__Main__() {
    __ParseArgs__ "$@"
    __Verification__

    [[ -z "$TMPDIR" ]] && __MakeTmpDir__
    cd "$TMPDIR" || exit 1

    if [[ -n "$INPUT_FILE" ]]; then
        __OpenFile__
    else
        __Download__
    fi

    __FindLinks__
    __ShowLinks__
    __FindHosts__
    __ShowHosts__
    __CrawlSimple__
    __LiveHosts__
    __FindComments__
    __ShowComments__
    __ShowResume__
    __ExportLiveHosts__
    __OutputJson__
    __Clear__
}

# ==============================================================================
# Início do programa
# ==============================================================================

__Main__ "$@"

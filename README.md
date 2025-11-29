<h1 align="center">🔎 Parsing HTML  (versão 1.0)</h1>

<p align="center">
  <b>Extrator avançado de links, hosts e análise de DNS diretamente em Bash</b><br>
  🟢 Portável • 🔐 Seguro • ⚡ Rápido • 🌐 Compatível com Linux/macOS
</p>

---

## ✨ Sobre o Projeto

Desenvolvi o **Parsing HTML 1.0** como uma ferramenta prática para auxiliar em atividades de análise, coleta de informação e reconhecimento técnico.  
A ideia é simples: dado um site ou arquivo HTML, o script identifica links relevantes, extrai todos os hosts presentes e verifica automaticamente quais deles estão ativos via DNS.  

Criei essa versão priorizando segurança, portabilidade e facilidade de uso — tudo em Bash puro, sem depender de bibliotecas externas.  
É uma ferramenta leve, direta e pensada para integrar etapas iniciais de recon, OSINT ou pentests autorizados.


Ele permite:

- 📥 Baixar páginas HTML (ou usar um arquivo local)
- 🔎 Extrair todos os links úteis (href, action)
- 🌐 Extrair hosts e domínios automaticamente
- 🧪 Testar quais hosts estão vivos via DNS
- 🎨 Saída amigável com cores, tags e organização
- 🔒 Uso seguro com diretórios temporários (`mktemp`)

---

## 🚀 Funcionalidades

✔ Suporte a URL ou arquivo HTML  
✔ Extração robusta de links  
✔ Extração inteligente de hosts (.com, .net, .gov, etc.)  
✔ Resolução DNS para detectar hosts ativos  
✔ Saída com tags:

- 🟩 **[LIVE]** – Host ativo com IPv4/IPv6  
- 🟨 **[RESOLVE]** – Resolve parcialmente  
- 🟥 **[DEAD]** – Não responde  

✔ Não usa `sed -i` → compatível com macOS e Linux  
✔ Limpeza automática com `Ctrl + C` (trap integrada)

---

## 📦 Dependências

São todas ferramentas comuns de terminal:

| Ferramenta | Usada para |
|-----------|------------|
| `wget` | Download da página web |
| `host` | Teste de DNS |
| `grep` | Extração de padrões |
| `sed` | Normalização de dados |
| `awk` | Processamento de colunas |
| `sort` | Ordenação e deduplicação |

O script verifica automaticamente a presença delas.

---

## 📥 Instalação

```bash
git clone https://github.com/SEU-USUARIO/parsing-html.git
cd parsing-html
chmod +x parsing_html.sh

````

## 🧠 Uso

### 🔎 Analisar uma página pela URL

```shell
./parsing_html.sh https://exemplo.com
```

📄 Analisar um arquivo HTML local

```shell
./parsing_html.sh -f pagina.html
```


📘 Ver ajuda

```shell
./parsing_html.sh -h
```

[+] Download do site...

##########################################################################
#                         Links encontrados                                    #
##########################################################################

https://alvo.com/login
https://alvo.com/assets/app.js

##########################################################################
#                         Hosts encontrados                                    #
##########################################################################

alvo.com
cdn.alvo.com

##########################################################################
#                            Hosts ativos                                      #
##########################################################################

[LIVE]   alvo.com        104.20.31.10
[DEAD]   cdn.alvo.com

===============================================================

Found :
        Links : 12
        Hosts : 4
===============================================================


## 🧱 Arquitetura Interna

O fluxo de execução segue a ordem:

1. 🔍 Verificação de dependências
    
2. 🏗 Criação de diretório temporário seguro
    
3. 📥 Download / abertura do arquivo
    
4. 🔎 Extração de links (href/action)
    
5. 🌐 Extração de hosts
    
6. 🧪 Testes de DNS
    
7. 🎨 Exibição formatada
    
8. 
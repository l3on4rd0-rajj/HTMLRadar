<h1 align="center">🔎 Parsing HTML  (versão 2.3)</h1>

<p align="center">
  <b>Extrator avançado de links, hosts, comentários HTML e análise de DNS diretamente em Bash</b><br>
  🟢 Portável • 🔐 Seguro • ⚡ Rápido • 🌐 Compatível com Linux/macOS
</p>

---

## ✨ Sobre o Projeto

Desenvolvi o **Parsing HTML 2.3** como uma ferramenta prática para auxiliar em atividades de análise, coleta de informação e reconhecimento técnico.  
A ideia é simples: dado um site ou arquivo HTML, o script identifica links relevantes, extrai todos os hosts presentes, verifica automaticamente quais deles estão ativos via DNS e agora também **mapeia comentários HTML (`<!-- ... -->`)**, que muitas vezes escondem:

- TODOs
- Comentários de desenvolvedores
- Dicas de infraestrutura
- Possíveis informações sensíveis esquecidas no código

Criei essa versão priorizando segurança, portabilidade e facilidade de uso — tudo em Bash puro, sem depender de bibliotecas externas.  
É uma ferramenta leve, direta e pensada para integrar etapas iniciais de recon, OSINT ou pentests autorizados.

Ele permite:

- 📥 Baixar páginas HTML (ou usar um arquivo local)
- 🔎 Extrair todos os links úteis (`href`, `action`)
- 🌐 Extrair hosts e domínios automaticamente
- 🧪 Testar quais hosts estão vivos via DNS
- 📝 Mapear comentários HTML da página (`<!-- ... -->`)
- 🎨 Saída amigável com cores, tags e organização
- 🔒 Uso seguro com diretórios temporários (`mktemp`)

---

## 🚀 Funcionalidades

✔ Suporte a URL ou arquivo HTML  
✔ Extração robusta de links (`href`, `action`)  
✔ Extração inteligente de hosts (.com, .net, .gov, etc.)  
✔ Resolução DNS para detectar hosts ativos  
✔ Mapeamento de comentários HTML com:

- Exibição de todos os blocos `<!-- ... -->`
- Suporte a comentários de múltiplas linhas
- Seção dedicada no output quando habilitado

✔ Saída com tags:

- 🟩 **[LIVE]** – Host ativo com IPv4/IPv6  
- 🟨 **[RESOLVE]** – Resolve parcialmente  
- 🟥 **[DEAD]** – Não responde  

✔ Não usa `sed -i` → compatível com macOS e Linux  
✔ Limpeza automática com `Ctrl + C` (trap integrada)  
✔ Diretório temporário isolado por execução com `mktemp`  

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
```

## 🧱 Arquitetura Interna

O fluxo de execução segue a ordem:

1. 🔍 **Verificação de dependências**  
   Confere se `wget`, `grep`, `sed`, `awk`, `host` e `sort` estão disponíveis no sistema.

2. 🏗 **Criação de diretório temporário seguro**  
   Utiliza `mktemp` para isolar arquivos durante o processamento.

3. 📥 **Download / abertura do arquivo**  
   - Se for URL → baixa o HTML com `wget`  
   - Se for arquivo local → copia para o diretório temporário  

4. 🔎 **Extração de links (href/action)**  
   Processa atributos `<a href="">`, `<form action="">` e similares.

5. 🌐 **Extração de hosts**  
   Identifica domínios e subdomínios presentes nos links extraídos.

6. 🧪 **Testes de DNS**  
   Usa o comando `host` para verificar quais hosts estão ativos, resolvendo IPv4 e IPv6.

7. 📝 **Extração de comentários HTML (`<!-- ... -->`)**  
   Executada apenas quando os parâmetros `-c` ou `--comments` são usados.  
   Suporta comentários de múltiplas linhas.

8. 🎨 **Exibição formatada**  
   Mostra:
   - Links encontrados  
   - Hosts identificados  
   - Hosts vivos (LIVE/RESOLVE/DEAD)  
   - Comentários HTML (se habilitado)  
   - Resumo final  

9. 🧹 **Limpeza do diretório temporário**  
   Remove todos os arquivos temporários ao final da execução.

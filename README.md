[+] Download do site...

##########################################################################
#                         Links encontrados                              #
##########################################################################

https://alvo.com/login
https://alvo.com/assets/app.js

##########################################################################
#                         Hosts encontrados                              #
##########################################################################

alvo.com
cdn.alvo.com

##########################################################################
#                            Hosts ativos                                #
##########################################################################

[LIVE]   alvo.com        104.20.31.10
[DEAD]   cdn.alvo.com

##########################################################################
#                    Comentários HTML encontrados                         #
##########################################################################

<!-- TODO: implementar validação extra -->
<!-- Versão antiga da home comentada
<div class="old-home">...</div>
-->

===============================================================

Found :
        Links      : 12
        Hosts      : 4
        Comentários: 3
===============================================================

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


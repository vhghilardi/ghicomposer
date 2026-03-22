# GhiComposer

Plugin **Open Tools API (OTA)** para o RAD Studio (Delphi) que abre uma janela para escrever **prompts** e pedir a um modelo de IA para **gerar ou corrigir código** diretamente na **unit aberta no editor** (arquivos `.pas`, `.dfm` em modo texto, etc.).

## Requisitos

- **RAD Studio** com Delphi (recomendado **10.4 Sydney** ou superior).
- Pacotes de sistema: `rtl`, `vcl`, `designide`.
- Conta e **API key** em um serviço compatível com a API **OpenAI Chat Completions** (ou proxy com o mesmo formato JSON).

## Instalação

1. Abra o `GhiComposer.dpk` no RAD Studio.
2. **Project → Build** para compilar o pacote.
3. **Component → Install** (ou instale o pacote de design-time conforme a versão do seu IDE).
4. Reinicie o IDE se for solicitado.

Após instalar, o expert aparece no menu com o texto **GhiComposer...** (a localização exata depende da versão do RAD Studio; em geral fica em **Tools** / **Ferramentas** ou na área de experts do IDE).

## Utilização

1. Abra no editor o arquivo que deseja alterar (por exemplo um `.pas` ou um `.dfm` como texto).
2. Opcional: **selecione** só o trecho a alterar.
3. Abra **GhiComposer...** pelo menu do expert.
4. Escreva o **prompt** (o que você quer que o modelo faça).
5. Configure a conexão na aba **API**:
   - **Endpoint** — padrão: `https://api.openai.com/v1/chat/completions`
   - **Modelo** — por exemplo: `gpt-4o-mini`
   - **API Key** — chave do seu provedor
6. Opção **Apenas texto selecionado**:
   - **Marcada**: envia e substitui só a região selecionada (é obrigatório haver seleção).
   - **Desmarcada**: envia o **arquivo inteiro** e pode substituir tudo no editor.
7. Clique em **Executar**. Quando a resposta chegar, confirme se deseja **substituir o código no editor**.

O texto retornado pelo modelo aparece na área **Resultado / status** antes de você aplicar.

### Abas

- **Chat** — prompt e opções do editor.
- **API** — URL, modelo e chave.
- **Opções avançadas** — prompt de sistema, timeouts HTTP, remoção de cercas markdown, temperatura e *max tokens* (gravados no mesmo INI).

## Configuração persistente

As configurações (URL, modelo, API key, opções de seleção e avançadas) são salvas em um arquivo **INI**:

- **Windows**: em geral `Documentos\GhiComposer.ini` (pasta Documentos do usuário).

**Segurança:** a API key fica em texto no INI. Em máquinas compartilhadas, use permissões de arquivo ou variáveis de ambiente em outro fluxo se você adaptar o código.

## Estrutura do repositório

| Caminho | Descrição |
|--------|-----------|
| `GhiComposer.dpk` | Pacote de design-time |
| `Sources/GhiComposer.Register.pas` | Registro do expert (`Register`) |
| `Sources/GhiComposer.Wizard.pas` | Wizard de menu **GhiComposer** |
| `Sources/GhiComposer.DockRef.pas` | Referência global do formulário acoplável |
| `Sources/GhiComposer.Editor.pas` | Leitura/escrita no buffer do editor (OTA, UTF-8) |
| `Sources/GhiComposer.AI.pas` | Cliente HTTP + JSON (`chat/completions`) |
| `Sources/uGhiComposerForm.pas` / `.dfm` | Formulário principal |

## Compatibilidade da API

O cliente assume um endpoint **POST** com corpo JSON no estilo OpenAI (`model`, `messages` com `system`/`user`) e resposta com `choices[0].message.content`. Serviços com o mesmo contrato (por exemplo alguns proxies ou APIs compatíveis) devem funcionar desde que a URL e os headers (`Authorization: Bearer …`) estejam corretos.

## Arquivos `.dfm`

O GhiComposer atua sobre o **conteúdo que o IDE mostra no editor de código**. Um `.dfm` precisa estar aberto como **texto** (não só no designer visual) para leitura/escrita linha a linha.

## Resolução de problemas

- **Nada acontece no editor**: confirme que há um módulo de código ativo e que você confirmou a substituição na caixa de diálogo.
- **Erro HTTP / JSON**: verifique URL, key, modelo e cotas do provedor; leia a mensagem na área de status.
- **Compilação**: em Delphi mais antigo, se `IOTAEditWriter.Insert(string)` não existir, pode ser necessário usar `Insert` com buffer UTF-8 conforme a sua `ToolsAPI.pas`.

## Licença

Sem licença explícita definida neste repositório — use e adapte conforme as suas necessidades e as licenças das bibliotecas da Embarcadero.

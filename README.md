# GhiComposer

Plugin **Open Tools API (OTA)** para o RAD Studio (Delphi) que abre uma janela para escrever **prompts** e pedir a um modelo de IA para **gerar ou corrigir código** diretamente na **unit aberta no editor** (ficheiros `.pas`, `.dfm` em modo texto, etc.).

## Requisitos

- **RAD Studio** com Delphi (recomendado **10.4 Sydney** ou superior).
- Pacotes de sistema: `rtl`, `vcl`, `designide`.
- Conta e **API key** num serviço compatível com a API **OpenAI Chat Completions** (ou proxy com o mesmo formato JSON).

## Instalação

1. Abrir `GhiComposer.dpk` no RAD Studio.
2. **Project → Build** para compilar o pacote.
3. **Component → Install** (ou instalar o pacote de design-time conforme a tua versão do IDE).
4. Reiniciar o IDE se for pedido.

Após instalar, o expert aparece no menu com o texto **GhiComposer...** (a localização exacta depende da versão do RAD Studio; costuma estar em **Tools** ou na área de experts do IDE).

## Utilização

1. Abrir no editor o ficheiro que queres alterar (por exemplo um `.pas` ou um `.dfm` como texto).
2. Opcional: **selecionar** só o trecho a alterar.
3. Abrir **GhiComposer...** a partir do menu do expert.
4. Escrever o **prompt** (o que queres que o modelo faça).
5. Configurar ligação:
   - **Endpoint** — por defeito: `https://api.openai.com/v1/chat/completions`
   - **Modelo** — por exemplo: `gpt-4o-mini`
   - **API Key** — chave do teu fornecedor
6. Opção **Apenas texto selecionado**:
   - **Marcada**: envia e substitui só a região seleccionada (é obrigatório haver seleção).
   - **Desmarcada**: envia o **ficheiro inteiro** e pode substituir tudo no editor.
7. Clicar **Executar**. Quando a resposta chegar, confirma se queres **substituir o código no editor**.

O texto devolvido pelo modelo aparece na área **Resultado / estado** antes de aplicares.

## Configuração persistente

As definições (URL, modelo, API key, opção de só seleção) são gravadas num ficheiro **INI**:

- **Windows**: normalmente `Documents\GhiComposer.ini` (pasta Documentos do utilizador).

**Segurança:** a API key fica em texto no INI. Em máquinas partilhadas, usa permissões de ficheiro ou variáveis de ambiente noutro fluxo se adaptares o código.

## Estrutura do repositório

| Caminho | Descrição |
|--------|-----------|
| `GhiComposer.dpk` | Pacote de design-time |
| `Sources/GhiComposer.Register.pas` | Registo do expert (`Register`) |
| `Sources/GhiComposer.Wizard.pas` | Wizard de menu **GhiComposer** |
| `Sources/GhiComposer.Editor.pas` | Leitura/escrita no buffer do editor (OTA, UTF-8) |
| `Sources/GhiComposer.AI.pas` | Cliente HTTP + JSON (`chat/completions`) |
| `Sources/uGhiComposerForm.pas` / `.dfm` | Formulário principal |

## Compatibilidade da API

O cliente assume um endpoint **POST** com corpo JSON no estilo OpenAI (`model`, `messages` com `system`/`user`) e resposta com `choices[0].message.content`. Serviços com o mesmo contrato (por exemplo alguns proxies ou APIs compatíveis) devem funcionar desde que o URL e os headers (`Authorization: Bearer …`) sejam os correctos.

## Ficheiros `.dfm`

O GhiComposer actua sobre o **conteúdo que o IDE mostra no editor de código**. Um `.dfm` tem de estar aberto como **texto** (não só no designer visual) para leitura/escrita linha a linha.

## Resolução de problemas

- **Nada acontece no editor**: confirma que há um módulo de código activo e que confirmaste a substituição na caixa de diálogo.
- **Erro HTTP / JSON**: verifica URL, key, modelo e quotas do fornecedor; lê a mensagem na área de estado.
- **Compilação**: em Delphi mais antigo, se `IOTAEditWriter.Insert(string)` não existir, pode ser necessário usar `Insert` com buffer UTF-8 conforme a tua `ToolsAPI.pas`.

## Licença

Sem licença explícita definida neste repositório — usa e adapta conforme as tuas necessidades e as licenças das bibliotecas do Embarcadero.

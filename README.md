# RobinhoNetCell — Sistema de Gestão de Ordem de Serviço (OS)

Sistema web responsivo (Mobile, Tablet e Desktop / PWA para iPhone) para gerenciamento de **Ordem de Serviço (OS)**, **Recibos de Quitação** e **Consulta em Tempo Real do Cliente** da **RobinhoNetCell**.

Aplicativo de arquivo único (`index.html`), sem servidor e sem instalação: os dados ficam salvos no próprio navegador (localStorage) e são sincronizados com o banco no **Supabase**, mantendo o funcionamento offline.

## Funcionalidades

- **Dashboard & KPIs:** OS Abertas, Em Manutenção, Aguardando Peça, Prontas para Retirada e Faturamento do Mês.
- **Cadastro de OS em 1 Clique:** Seleção rápida de marca (Apple, Samsung, Motorola, Xiaomi, Realme, ASUS, LG), catálogo clicável de modelos, cores, checklist de entrada e desenho de padrão Android 3x3.
- **Consulta em Tempo Real do Cliente:** Acompanhamento visual por etapas com número da OS e validação pelos **4 últimos dígitos** do telefone/CPF (o número pode ser digitado como `OS-0001`, `0001` ou `1`).
- **Link de acompanhamento pelo WhatsApp:** a loja envia um link que abre a tela exclusiva do cliente (`cliente.html`), já preenchida e validada, com o status **atualizado automaticamente a cada 10 segundos** (e ao voltar para a aba). Essa página não tem nenhum botão de editar, criar ou excluir OS — apenas consulta.
- **Recibo de Quitação & Impressão:** emissão de recibo pós-execução com **CNPJ e endereço da loja** no cabeçalho, forma de pagamento e garantia legal de 90 dias (CDC); o envio pelo WhatsApp gera o recibo em **PDF** (anexo no celular quando o navegador permite compartilhar arquivos, ou download + envio no desktop), além da impressão em A4 ou cupom 80mm.
- **Pré-visualização antes de imprimir/enviar:** o recibo e a OS abrem em uma tela de conferência com alternância entre **Recibo/OS** e **A4/Cupom 80mm**, aviso quando o pagamento ainda não foi registrado e botões de imprimir, **baixar PDF** e enviar no WhatsApp.
- **Senha de acesso à edição:** o painel da loja só libera a edição de OS depois de uma senha. No primeiro acesso a tela pede para **criar a senha** (mínimo de 6 caracteres). Depois disso ela é pedida a cada nova sessão do navegador; os botões **Bloquear edição** e **Alterar senha de acesso** ficam no menu lateral (e o ícone de cadeado no topo, no celular). A senha fica salva apenas como hash SHA-256 no navegador da loja.
- **Autorização do cliente:** na tela de acompanhamento o cliente marca que autoriza a execução do serviço; a loja vê o status **AUTORIZADO** no detalhe da OS e no documento impresso.
- **Aba de pagamento (cliente):** mostra como o valor foi recebido (**PIX, Dinheiro/espécie, Cartão de Crédito/Débito ou Transferência**), valor e data; após pagamento confirmado **e** OS entregue, o cliente pode baixar o recibo em PDF.
- **Clientes & Histórico:** Cadastro de clientes com histórico de todas as OS do aparelho/telefone.
- **Edição e Exclusão de OS:** Alteração de status em um clique e exclusão com confirmação.
- **Numeração sequencial:** as OS são numeradas em sequência e o número de uma OS excluída **não é reaproveitado**.
- **Sincronização na nuvem:** envio automático ao salvar, download ao abrir o app e botões manuais de enviar/baixar no menu de backup.
- **Backup:** exportação/restauração de clientes e ordens em `.json`, além do download do próprio `index.html`.
- **PWA para iPhone (iOS):** Pode ser adicionado diretamente à Tela de Início pelo Safari.

## Como publicar no GitHub Pages

1. Envie os arquivos deste pacote (`index.html` e `README.md`) para o repositório no GitHub.
2. Acesse **Settings > Pages**, selecione a branch `main` e a pasta `/ (root)` e clique em **Save**.

## Banco na nuvem (Supabase)

O app já está conectado ao projeto `zubrrdburxbdduksfhxr.supabase.co`:

- **Envio automático** da OS/cliente assim que você salva, altera status, registra pagamento ou exclui.
- **Download automático** (mesclagem sem apagar) ao abrir o app.
- **Enviar/Baixar manualmente** em *Exportar App / Backup → 3. Nuvem (Supabase)*.
- **Offline:** se a internet cair, o app continua salvando no aparelho e o botão *Enviar para a nuvem* recupera o atraso.

Se precisar recriar o banco do zero:

1. No painel do Supabase, abra **SQL Editor > New query**.
2. Cole todo o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique em **Run**.
3. Confira em **Table Editor** se as tabelas `clients`, `orders`, `receipts` e `shop_settings` foram criadas.

O schema cria numeração automática de OS, índices e políticas de acesso, e pode ser executado novamente sem apagar dados.

Para ativar a **autorização do cliente**, execute também [`supabase/migration_autorizacao.sql`](supabase/migration_autorizacao.sql) no SQL Editor (cria `authorized_at` e `authorized_by` em `orders`). Quem vai recriar o banco do zero não precisa: o `schema.sql` já foi atualizado.

> ⚠️ **Segurança:** o modo configurado é **sem login (anon liberado)**, escolhido para uso interno da loja. Como a chave anon fica visível no site publicado, qualquer pessoa com o link pode ler e alterar os dados. Se o sistema ficar público, migre para login com Supabase Auth.

## Acompanhamento pelo WhatsApp (tempo real)

No detalhe da OS, use **Enviar link de acompanhamento** (abre o WhatsApp com a mensagem pronta) ou **Copiar link**. O link tem este formato:

```
https://robsonsilva-sys.github.io/OS/cliente.html?os=OS-0001&pin=1234
```

Ao abrir, a página **[`cliente.html`](cliente.html)** consulta a OS com os 4 últimos dígitos e fica **ao vivo**: busca o status no Supabase a cada 10 segundos e também quando a aba volta ao foco. Assim, quando a loja mudar o status para *Em Manutenção*, *Pronta para Retirada* etc., a tela do cliente atualiza sozinha.

Essa página é **somente de acompanhamento**: não exibe menu de gestão, não tem botões de criar/editar/excluir OS e não dá acesso ao aplicativo da loja (`index.html`). O painel continua disponível apenas em `index.html`.

Dentro dela o cliente pode:
1. **Autorizar o serviço** com um checkbox e um clique — a loja vê o status no detalhe da OS;
2. Abrir a aba **Pagamento** e conferir se foi **PIX, Dinheiro, Cartão ou Transferência**, o valor e a data;
3. **Baixar o recibo em PDF** assim que o pagamento for confirmado e a OS estiver *Entregue*.

> O link só funciona enquanto o site estiver publicado e o banco acessível. O PIN é apenas os 4 últimos dígitos do telefone/CPF já usados no atendimento — não compartilhe o link com terceiros.

## Manter o banco ativo (a cada 2 dias)

O plano gratuito do Supabase pausa o projeto após ~7 dias sem uso. Há duas proteções:

1. **GitHub Actions (principal):** [`.github/workflows/supabase-keepalive.yml`](.github/workflows/supabase-keepalive.yml) consulta o banco a cada 2 dias (`0 8 */2 * *`, 08:00 UTC) e também pode ser disparado manualmente na aba **Actions** do repositório.
2. **Automação local (reserva):** job `Supabase keep-alive (a cada 2 dias)` no OpenCode, que roda às 09:00 (Brasília) quando o app estiver aberto.

> O GitHub desativa agendamentos de repositórios sem atividade por 60 dias — qualquer commit reativa. Se preferir não usar GitHub Actions, cadastre a mesma URL em um monitor gratuito (UptimeRobot, cron-job.org) a cada 2 dias.


## Importante

- **Faça backup com frequência.** Há duas cópias: no navegador do aparelho e no Supabase. Use **Exportar App / Backup > Exportar Dados (.json)** antes de limpar o navegador.
- **Conexão com a internet:** a interface usa Tailwind CSS, ícones Lucide, fonte Inter e a biblioteca do Supabase via CDN. Sem internet o app continua abrindo e salvando localmente (com a aparência simplificada); ao voltar a conexão, use *Enviar para a nuvem*.
- O arquivo `index.html` é autossuficiente: para atualizar o sistema, basta substituir esse arquivo no repositório.

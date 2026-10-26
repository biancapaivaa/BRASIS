# BRASIS · Uma jornada de histórias e culturas

**Versão cultural 2.0.** Uma aventura virtual pelas cinco regiões brasileiras.
As missões são sobre música, dança, festas, literatura, arquitetura, culinária e saberes.
A estética é de jogo de viagem: ilustrações vetoriais próprias, tipografia Nunito,
botões com relevo, roteiro de capítulos, carimbos e passaporte de conquistas.

## Atualizando o projeto que você já abriu

1. Pare o aplicativo antigo com `Ctrl + C` no terminal.
2. Extraia este ZIP em uma pasta nova. Abra a pasta `brasis`, que contém `pubspec.yaml`, no VS Code.
3. Copie seu **config.json** do projeto anterior para essa nova pasta. Não envie chaves secretas.
4. No **mesmo projeto Supabase**, abra **SQL Editor → New query**, cole TODO o novo
   `supabase/schema.sql` e clique em **Run**. Esse arquivo funciona tanto em banco novo
   quanto na versão anterior; pode ser executado novamente.
5. No terminal, dentro da nova pasta `brasis`, execute:

```powershell
flutter pub get
```

Depois:

```powershell
flutter run -d chrome --web-port=3000 --dart-define-from-file=config.json
```

**Não precisa executar `flutter create`: a pasta `web` já está pronta.**
Se não tiver `config.json`, copie `config.example.json` com outro nome e preencha a URL
Supabase e a chave pública publishable/anon. A chave `service_role` ou secret não deve ir no app.
Não precisa de Python, ponte MQTT, novo projeto Supabase nem reinstalar o Flutter.

### O que acontece com a versão anterior
- Contas, apelidos, e-mails e sessões continuam funcionando.
- As missões anteriores ficam inativas e saem do aplicativo.
- O histórico anterior não é apagado. A pontuação anterior fica guardada em `profiles.legacy_points`.
- Os pontos exibidos no app e no ranking passam a contar **somente a nova jornada cultural**.
- Conquistas antigas são arquivadas; as seis conquistas culturais são desbloqueadas no novo roteiro.
- Se executar o SQL novamente depois de jogar, o progresso cultural é preservado e os pontos são reconciliados.

## Como jogar

**Norte → Nordeste → Centro-Oeste → Sudeste → Sul.**

Cada capítulo tem três paradas. Você pode espiar as regiões futuras, mas precisa concluir
as paradas anteriores para jogar as seguintes. Cada missão tem:

1. **A descoberta:** um texto curto sobre uma expressão cultural e seu contexto.
2. **Sua vez de explorar:** uma atividade autoral para registrar no diário (8 a 600 caracteres).
3. **Bateu a curiosidade?:** uma pergunta com três opções, conferida no servidor.

Clique em **Embarcar nesta missão**, leia, escreva sua descoberta e escolha a resposta.
Resposta incorreta permite tentar novamente sem perder pontos. Resposta correta com diário
preenchido concede XP uma única vez. Três paradas concluídas geram o carimbo da região e
liberam o capítulo seguinte. A cada 300 XP, você sobe um nível.
A qualidade do texto do diário é autodeclarada; o protótipo valida seu tamanho, não seu conteúdo.
A viagem é virtual: não usa GPS, não exige deslocamento, compras ou consumo de alimentos.

| Região | Paradas |
|---|---|
| Norte | Carimbó; cuias do Baixo Amazonas; tacacá |
| Nordeste | Frevo; literatura de cordel; ofício das baianas de acarajé |
| Centro-Oeste | Viola de cocho; festas e cavalhadas de Goiás; Brasília |
| Sudeste | Jongo; queijos artesanais mineiros; matrizes do samba |
| Sul | Fandango caiçara; chimarrão; boi de mamão |

As paradas são exemplos, e não resumos de uma região inteira. O aplicativo reconhece que
as culturas atravessam fronteiras, como o fandango caiçara entre Paraná e São Paulo, e
contextualiza o protagonismo de povos indígenas, comunidades negras, artesãs e outros detentores.
As fontes estão indicadas em cada missão e em `supabase/content.json`.

## Telas

- Abertura com a logo original e animação.
- Login e cadastro com Supabase Auth, validação e mensagens de erro.
- Jornada com capítulo atual, XP e roteiro das cinco regiões.
- Região com ilustração, progresso e três paradas.
- Missão com descoberta, diário, questão e retorno de acerto.
- Passaporte com cinco carimbos e seis conquistas bloqueadas/desbloqueadas.
- Ranking do banco com três destaques, top 100 e a posição do usuário.
- Perfil com nível, pontos, carimbos, conquistas, diário e logout.
- GoRouter, proteção de sessão, carregamento, erro com nova tentativa e gesto para atualizar.

## Primeiro uso em um Supabase novo

Execute `supabase/schema.sql` **antes de cadastrar contas**. Habilite autenticação por
e-mail e senha. Com confirmação de e-mail habilitada, configure **Site URL** como
`http://localhost:3000`, confirme a conta no e-mail e volte ao aplicativo para entrar.
Para publicação, configure suas URLs e deep links conforme o destino escolhido.
Se já havia contas no banco antes da instalação inicial do BRASIS, crie os perfis ausentes:

```sql
insert into public.profiles(id,nickname,legacy_points)
select id,left(coalesce(nullif(trim(raw_user_meta_data->>'nickname'),''),'Viajante'),40),0
from auth.users on conflict(id) do nothing;
```

## Plataformas e requisitos

Flutter estável **3.35+** e Dart **3.9+**. Seu Flutter 3.47 atende à faixa declarada.
A versão entregue já está preparada para **Chrome**, sem depender da geração de ícones
padrão pelo `flutter create` que falhou na sua instalação.

Para Android, depois de validar a Web, gere a plataforma com:

```bash
flutter create --platforms=android --project-name brasis .
```

Não use `--overwrite`. Adicione antes de `<application` em
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Depois execute `flutter run --dart-define-from-file=config.json` com o aparelho conectado.
Para iOS, é preciso macOS/Xcode e gerar o projeto iOS. Nenhum APK foi pré-compilado.

## Estrutura

- `lib/main.dart`: configuração, tema, splash, acesso e rotas.
- `lib/pages.dart`: jornada, regiões, missão, passaporte, ranking e perfil.
- `lib/data.dart`: repositório, modelos, regras visuais de progresso e mensagens.
- `lib/widgets.dart`: GameButton, MissionCard, ProgressCard, AchievementBadge, PassportStamp e ilustrações.
- `assets/logo.png`: logo original fornecida.
- `assets/fonts/`: Nunito local e sua licença OFL.
- `web/index.html`: entrada Web pronta.
- `supabase/schema.sql`: instalação e migração idempotente.
- `supabase/content.json`: fonte editorial e gabarito do proprietário, não incluído nos assets do cliente.
- `test/widget_test.dart`: testes de sequência e componentes em Flutter.
- `verification/`: testes do banco em PostgreSQL embarcado, com usuários de teste isolados.

## Regras do banco e privacidade

Os dados são persistidos no Supabase. As políticas RLS permitem ver somente o próprio
perfil, progresso, anotações e conquistas. O ranking expõe UUID, apelido público,
pontos e posição, sem e-mail ou diário.

O cliente não pode escrever diretamente em pontos, conclusões ou conquistas. A RPC
`mission_action` autentica, bloqueia a linha do perfil e confere a sequência, o estado,
a resposta e o tamanho da anotação. Conclusão, pontos e conquistas são registrados juntos.
A mesma missão concluída retorna zero XP. O lock serializa ações concorrentes do jogador.
O gabarito está na tabela `mission_answers`, sem acesso de leitura para anon/authenticated.
Conquistas por dias contam datas distintas no fuso America/Sao_Paulo, não dias consecutivos.
O ranking é ordenado por pontos, data de cadastro e UUID para desempate estável.

## Validação

No seu computador:

```bash
flutter analyze
flutter test
```

Teste também com duas contas: inicie uma missão, feche o app, retorne e confira o estado;
conclua e confira os pontos; tente repetir; tente pular uma região; erre a pergunta;
confira o diário depois de novo login; verifique o ranking na segunda conta.

Os testes de banco incluídos usam PGlite (PostgreSQL embarcado) e reproduzem as roles
`anon`/`authenticated`, RLS e `auth.uid()` sem acessar seu Supabase:

```bash
cd verification
npm install
npm test
```

Eles não substituem testes da integração Auth/PostgREST no seu projeto real.
Veja `VALIDACAO.md` para os resultados e os limites da verificação desta entrega.

## Fontes culturais e licenças

Conteúdo editorial original, com consulta a páginas do Iphan/Bens Culturais Registrados,
Ministério do Turismo e NDI/UFSC. URLs por missão no banco. Não inclui letras de músicas
nem reproduções extensas das fontes. Ilustrações em Canvas são autorais e estilizadas;
não são mapas geográficos oficiais. Nunito: SIL Open Font License, incluída no pacote.

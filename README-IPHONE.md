# Controle de Casa no iPhone — caminho gratuito

## Situação atual

O caminho escolhido é o app nativo Flutter, instalado pelo SideStore com uma
conta Apple gratuita. O iPhone controla a TV diretamente; não depende de PC ou
Android ligado durante o uso. A primeira instalação precisa de cabo USB no
Windows. A assinatura gratuita expira após sete dias e precisa ser renovada.
O SideStore tenta renovar no próprio iPhone, mas falhas de renovação ou perda do
pareamento podem exigir intervenção ou reconexão ao Windows. Não é uma
instalação permanente e não usa assinatura paga da Apple.

O iPhone informado (provavelmente 16 Pro Max) atende ao mínimo do projeto:
iOS 15. Não foi feita compilação com Xcode nem teste físico desta adaptação.
Os testes no Windows não comprovam funcionamento no iOS.

## Compatibilidade da rede

- Autorize Rede Local no iPhone e faça a primeira conexão com a TV ligada.
- Autorize também o controle na televisão; o pareamento do Android não é
  automaticamente transferido para o iPhone.
- A busca usa Bonjour nativo, com os serviços declarados no Info.plist.
  Se a LG não anunciar um serviço compatível, use o botão + e informe o IP.
- O iPhone e a TV precisam estar na mesma rede, sem isolamento de dispositivos.
- Microfone e reconhecimento de fala são opcionais, solicitados ao usar voz.

### Ligar a TV: ainda experimental no iPhone

A Apple exige uma autorização especial para multicast/broadcast. Esta variante
gratuita não declara essa capacidade restrita e não tenta fazer SSDP bruto nem
enviar Wake-on-LAN por broadcast. O botão de ligar tenta enviar o pacote para o
IP da TV diretamente (unicast). O pacote é válido, mas isso só acorda a TV se a
TV e o roteador mantiverem a comunicação em espera; pode parar de funcionar
depois que a tabela de vizinhos do roteador expirar ou o IP mudar.

Não há garantia de paridade com o Android para ligar uma TV desligada. Testar
após poucos minutos e também após uma noite em espera. Se falhar, o controle
físico continua necessário para ligar; não rotular o recurso como validado.

## Compilar sem possuir um Mac

O Xcode continua obrigatório, mas pode rodar em um Mac hospedado no GitHub
Actions. O workflow manual `.github/workflows/ios-sideload.yml` compila release
para iPhone e cria um IPA sem assinatura. O SideStore aplica a assinatura da
conta Apple no momento da instalação. Nenhuma senha ou certificado Apple é
necessário no GitHub.

Os runners padrão são gratuitos em repositórios públicos. Em repositórios
privados dependem da cota da conta e das regras de cobrança; não assumir que
sejam ilimitados ou executar com cobrança habilitada. Publicar o código exige
decisão do proprietário. O pacote de fontes não inclui .tools, dist, chaves,
pareamentos, dados do usuário, notas de continuidade ou configurações geradas
com caminhos do computador.

Depois de aprovar a hospedagem dos fontes:

1. Subir o pacote limpo para um repositório GitHub.
2. Abrir Actions > iPhone - gerar IPA para SideStore > Run workflow.
3. Aguardar todas as etapas; baixar o artefato controle-de-casa-iphone-sidestore.
4. Descompactar o artefato para obter o IPA. Ele não é instalável diretamente
   tocando em um link no Safari; precisa ser assinado/instalado pelo SideStore.
5. Se a compilação falhar, corrigir o problema no log antes de prosseguir.

## Instalação e manutenção

Seguir os guias oficiais atuais do SideStore (eles podem mudar):

- Requisitos: https://docs.sidestore.io/docs/installation/prerequisites
- Instalação: https://docs.sidestore.io/docs/installation/install
- Limitações/renovação: https://docs.sidestore.io/docs/faq

Resumo: instalar o iloader no Windows; instalar LocalDevVPN no iPhone; conectar
o iPhone por cabo e confiar no computador; instalar SideStore pelo iloader;
confiar no app de desenvolvimento e habilitar Modo de Desenvolvedor conforme a
versão do iOS. Fazer a primeira renovação do SideStore antes de instalar o IPA.
Digitar credenciais Apple somente nos programas/páginas oficiais, nunca no chat.
O LocalDevVPN precisa estar conectado ao instalar/atualizar/renovar pelo
SideStore; não é uma ponte para o controle da TV.

Conta gratuita permite até três apps assinados simultaneamente, incluindo o
próprio SideStore. Para atualizar nosso controle, instalar o novo IPA sobre o
anterior, sem apagar o aplicativo. Conferir periodicamente a validade: a
renovação em segundo plano é uma tentativa, não uma garantia.

## Referências técnicas verificadas

- Apple, contas gratuitas e validade: https://developer.apple.com/help/account/basics/about-your-developer-account/
- Apple, autorização multicast/broadcast: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.multicast
- Flutter, necessidade de macOS/Xcode: https://docs.flutter.dev/deployment/ios
- GitHub, runners padrão e repositórios públicos: https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job

As lojas alternativas disponíveis no Brasil continuam exigindo a participação
do desenvolvedor no programa Apple e não resolvem a restrição de custo deste
projeto: https://developer.apple.com/support/app-distribution-in-brazil .

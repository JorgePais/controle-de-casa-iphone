// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Controle de Casa';

  @override
  String get switchTv => 'Trocar TV';

  @override
  String get inputLoadFailed =>
      'Não foi possível acessar as entradas. Confira a conexão com a TV.';

  @override
  String get noInputs => 'Nenhuma entrada externa encontrada.';

  @override
  String get volume => 'Volume';

  @override
  String get channels => 'Canais';

  @override
  String get guide => 'Guia';

  @override
  String get info => 'Informações';

  @override
  String get pairingHint =>
      'Na primeira conexão, autorize o controle na tela da TV.';

  @override
  String get selectDevice => 'Suas TVs';

  @override
  String get addManually => 'Adicionar TV';

  @override
  String get addTvManually => 'Adicionar uma TV';

  @override
  String get tvIpAddress => 'Endereço IP da TV';

  @override
  String get nameOptional => 'Nome (opcional)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Adicionar';

  @override
  String get scanning => 'Procurando na rede…';

  @override
  String get devicesFound => 'Escolha sua TV';

  @override
  String foundCount(int count) {
    return '$count aparelho(s) disponível(is)';
  }

  @override
  String get noDevicesFound => 'Nenhuma TV encontrada';

  @override
  String get noDevicesHint =>
      'Ligue a TV e conecte o celular\nà mesma rede de casa.';

  @override
  String get discoveryFailed => 'Não foi possível procurar TVs';

  @override
  String get scanAgain => 'Buscar TVs';

  @override
  String get noWifi => 'Conecte-se à rede de casa';

  @override
  String get noWifiHint =>
      'Use o Wi-Fi da sua casa para encontrar e controlar suas TVs.';

  @override
  String get wifiReconnected => 'Wi-Fi conectado';

  @override
  String get wifiDisconnected => 'Wi-Fi desconectado — confira sua conexão';

  @override
  String get remote => 'Controle';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get numericKeypad => 'Números';

  @override
  String get power => 'Desligar TV';

  @override
  String get connecting => 'Conectando…';

  @override
  String get reconnecting => 'Reconectando…';

  @override
  String get connected => 'Conectada';

  @override
  String get connectionError => 'Falha de conexão';

  @override
  String get disconnected => 'Desconectada';

  @override
  String get idle => 'Aguardando';

  @override
  String disconnectedReason(String reason) {
    return 'TV desconectada: $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Voltar';

  @override
  String get exit => 'Sair';

  @override
  String get smart => 'Início';

  @override
  String get input => 'Entradas';

  @override
  String get up => 'Cima';

  @override
  String get down => 'Baixo';

  @override
  String get left => 'Esquerda';

  @override
  String get right => 'Direita';

  @override
  String get volumeUp => 'Aumentar volume';

  @override
  String get volumeDown => 'Diminuir volume';

  @override
  String get mute => 'Mudo';

  @override
  String get channelUp => 'Próximo canal';

  @override
  String get channelDown => 'Canal anterior';

  @override
  String get menu => 'Configurações';

  @override
  String get more => 'Mais controles';

  @override
  String get rewind => 'Retroceder';

  @override
  String get record => 'Gravar';

  @override
  String get play => 'Reproduzir';

  @override
  String get stop => 'Parar';

  @override
  String get pause => 'Pausar';

  @override
  String get fastForward => 'Avançar';

  @override
  String get redButton => 'Botão vermelho';

  @override
  String get greenButton => 'Botão verde';

  @override
  String get yellowButton => 'Botão amarelo';

  @override
  String get blueButton => 'Botão azul';

  @override
  String get invalidIpv4 => 'Endereço IP inválido';

  @override
  String get enterIpAddress => 'Informe o endereço IP';

  @override
  String get lookingForTvs => 'Buscando TVs na sua rede…';

  @override
  String get brand => 'Marca';

  @override
  String get brandSamsung => 'Samsung';

  @override
  String get brandLg => 'LG';

  @override
  String ipLabel(String host) {
    return 'IP: $host';
  }

  @override
  String macLabel(String mac) {
    return 'MAC: $mac';
  }

  @override
  String get smartHub => 'Tela inicial';

  @override
  String get inputSource => 'Entradas HDMI e TV';

  @override
  String get unknown => 'motivo desconhecido';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'TV da sala';

  @override
  String get forgetTv => 'Remover esta TV';

  @override
  String forgetTvConfirm(String name) {
    return 'Remover $name e seu pareamento? Será necessário autorizar o app na TV novamente.';
  }

  @override
  String get forget => 'Remover';

  @override
  String connectionFailed(String reason) {
    return 'Não foi possível conectar: $reason';
  }
}

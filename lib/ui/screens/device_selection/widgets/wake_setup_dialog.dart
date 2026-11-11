import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/models/tv_mac.dart';

Future<String?> showWakeSetup(BuildContext context, TVDevice device) async {
  final form = GlobalKey<FormState>();
  final controller = TextEditingController(text: device.mac ?? '');
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Preparar para ligar a TV'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ative Ligar via Wi-Fi (TV ligada com dispositivo móvel) nas configurações da LG. A TV precisa estar na tomada e na mesma rede do celular.',
                ),
                const SizedBox(height: 12),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const Text(
                    'O recurso de ligar pelo iPhone ainda precisa ser validado na sua TV e na sua rede.',
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Ligue a TV e conecte uma vez para o app tentar guardar o MAC automaticamente. Se necessário, informe aqui o MAC do Wi-Fi da TV, disponível nos detalhes de rede dela.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'MAC Wi-Fi da TV',
                    hintText: 'AA:BB:CC:DD:EE:FF',
                  ),
                  validator: (value) => normalizeTvMac(value) == null
                      ? 'Informe os 6 pares de letras e números do MAC.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.of(dialog).pop(normalizeTvMac(controller.text));
              }
            },
            child: const Text('Salvar e ligar'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

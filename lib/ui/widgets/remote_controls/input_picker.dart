import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_input_control.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

Future<void> showTvInputs(BuildContext context) async {
  final bloc = context.read<TvConnectionBloc>();
  final device = bloc.state.device;
  if (device == null || !bloc.state.isConnected) return;
  if (TvBrand.fromDevice(device) != TvBrand.lg) {
    context.sendTvKey(KeyCodes.KEY_SOURCE);
    return;
  }
  final generationDevice = device;
  Future<List<TvInput>>? future;
  final selected = await showDialog<TvInput>(
    context: context,
    builder: (dialogContext) {
      final l = AppLocalizations.of(dialogContext);
      return AlertDialog(
        title: Text(l.input),
        content: SizedBox(
          width: 300,
          child: FutureBuilder<List<TvInput>>(
            future: future ??= bloc.inputs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text(l.inputLoadFailed);
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final inputs = snapshot.data!;
              if (inputs.isEmpty) return Text(l.noInputs);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final input in inputs)
                      ListTile(
                        leading: const Icon(Icons.input),
                        title: Text(input.label),
                        onTap: () => Navigator.of(dialogContext).pop(input),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
        ],
      );
    },
  );
  if (selected == null ||
      !context.mounted ||
      bloc.state.device != generationDevice) {
    return;
  }
  try {
    await bloc.selectInput(selected.id);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).inputLoadFailed)),
    );
  }
}

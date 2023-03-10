// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kid_demo/core/widgets/barcode_widget.dart';
import 'package:kid_demo/features/home/cubit/home_cubit.dart';
import 'package:kid_demo/features/receive_kid/cubit/receive_kid_cubit.dart';
import 'package:kid_demo/features/receive_kid/receive_kid_page.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/copy_field.dart';
import 'cubit/view_kid_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ViewKidCubit viewKidCubit = context.read();

    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) {
        state.maybeWhen(
          receivedFile: (file) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => ReceiveKidCubit(),
                child: ReceiveKidPage(
                  receivedFile: file,
                  viewKidCubit: viewKidCubit,
                ),
              ),
            ),
          ),
          orElse: () => null,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: context.read<ViewKidCubit>().refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BlocBuilder<ViewKidCubit, ViewKidState>(
                    builder: (context, state) {
                      return state.when(
                        initial: () => const Padding(
                          padding: EdgeInsets.only(bottom: 32),
                          child: Text(
                            '??adowanie identyfikatora KID...',
                          ),
                        ),
                        loaded: (kid) {
                          if (kid == null) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 32),
                              child: Text(
                                'Nie doda??e?? jeszcze identyfikatora KID, lub nie uda??o si?? go za??adowa??.',
                              ),
                            );
                          }

                          return Column(children: [
                            BarcodeWidget(kid: kid),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.maxFinite,
                              child: ElevatedButton(
                                onPressed: () => _shareKid(context),
                                child: const Text('UDOST??PNIJ KID'),
                              ),
                            ),
                          ]);
                        },
                      );
                    },
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.read<HomeCubit>().generateKid();
                        viewKidCubit.refresh();
                      },
                      child: const Text('POBIERZ KID'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.read<HomeCubit>().deleteKid();
                        viewKidCubit.refresh();
                      },
                      child: const Text('USU?? KID'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareKid(BuildContext context) async {
    final kidShare = await context.read<HomeCubit>().getEncryptedKid();
    if (kidShare == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nie uda??o si?? udost??pni?? identyfikatora KID. Upewnij si??, ??e wygenerowa??e?? identyfikator.',
          ),
        ),
      );

      return;
    }

    await showGeneralDialog(
      context: context,
      pageBuilder: (context, _, __) => AlertDialog(
        title: const Text('Udost??pnienie identyfikatora KID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aby uzyska?? dost??p do e-paragon??w skojarzonych z Twoim identyfikatorem KID w innej aplikacji:\n1. Skopiuj do schowka poni??sze has??o.\n2. Kliknij na przycisk UDOST??PNIJ.\n3. Wybierz aplikacj??, kt??rej chcesz udost??pni?? zaszyfrowany plik z identyfikatorem KID.\n4. Po uruchomieniu si?? wybranej aplikacji wklej skopiowane has??o.\n\nHas??o:\n',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            CopyField(textToCopy: kidShare.encryptionKey),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANULUJ'),
          ),
          TextButton(
            onPressed: () async {
              final fileToShare = XFile(kidShare.encryptedFile.path);
              await Share.shareXFiles([fileToShare]);
              Navigator.pop(context);
            },
            child: const Text('UDOST??PNIJ'),
          ),
        ],
      ),
    );
  }
}

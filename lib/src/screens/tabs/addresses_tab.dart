import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/bloc/bloc.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// تبويب العناوين (مكان مؤقت - يُستكمل لاحقاً).
class AddressesTab extends StatelessWidget {
  const AddressesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Center(
          child: Text(
            AppStrings.get(state.languageCode, 'addresses'),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      },
    );
  }
}

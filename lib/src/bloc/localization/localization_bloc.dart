import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class LocalizationEvent {
  const LocalizationEvent();
}

class LocalizationLanguageChanged extends LocalizationEvent {
  const LocalizationLanguageChanged(this.languageCode);
  final String languageCode;
}

// State
class LocalizationState {
  const LocalizationState({this.languageCode = 'en'});

  final String languageCode;

  /// RTL languages: Arabic and Kurdish
  bool get isRtl => languageCode == 'ar' || languageCode == 'ku';

  /// TextDirection based on language
  bool get isDirectionRtl => isRtl;

  LocalizationState copyWith({String? languageCode}) {
    return LocalizationState(languageCode: languageCode ?? this.languageCode);
  }
}

// BLoC
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  LocalizationBloc({String initialLanguageCode = 'en'})
    : super(LocalizationState(languageCode: initialLanguageCode)) {
    on<LocalizationLanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onLanguageChanged(
    LocalizationLanguageChanged event,
    Emitter<LocalizationState> emit,
  ) async {
    emit(state.copyWith(languageCode: event.languageCode));
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_repository.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final BluetoothRepository _bluetoothRepository;
  StreamSubscription? _adapterStateSubscription;

  BluetoothBloc(this._bluetoothRepository) : super(BluetoothInitialState()) {
    on<CheckBluetoothPermissions>(_onCheckPermissions);
    on<BluetoothStateChanged>(_onBluetoothStateChanged);
  }

  Future<void> _onCheckPermissions(
      CheckBluetoothPermissions event,
      Emitter<BluetoothState> emit,
      ) async {
    emit(BluetoothCheckingState());

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    bool allGranted = statuses.values.every(
          (status) => status.isGranted || status.isLimited,
    );

    if (!allGranted) {
      emit(BluetoothPermissionDeniedState());
      return;
    }

    bool isBtOn = await _bluetoothRepository.isBluetoothEnabled();

    if (isBtOn) {
      emit(BluetoothReadyState());
    } else {
      emit(BluetoothDisabledState());
    }

    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = _bluetoothRepository.adapterStateStream.listen(
          (isOn) {
        add(BluetoothStateChanged(isBluetoothOn: isOn));
      },
    );
  }

  void _onBluetoothStateChanged(
      BluetoothStateChanged event,
      Emitter<BluetoothState> emit,
      ) {
    if (event.isBluetoothOn) {
      emit(BluetoothReadyState());
    } else {
      emit(BluetoothDisabledState());
    }
  }

  @override
  Future<void> close() {
    _adapterStateSubscription?.cancel();
    return super.close();
  }
}
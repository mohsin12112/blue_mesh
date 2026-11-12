abstract class BluetoothEvent {}

class CheckBluetoothPermissions extends BluetoothEvent {}

class BluetoothStateChanged extends BluetoothEvent {
  final bool isBluetoothOn;
  BluetoothStateChanged({required this.isBluetoothOn});
}
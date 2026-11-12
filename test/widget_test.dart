import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:blue_mesh/bluetooth_repository.dart';
import 'package:blue_mesh/local_storage_repository.dart';
import 'package:blue_mesh/chat_bloc.dart';
import 'package:blue_mesh/chat_event.dart';
import 'package:blue_mesh/chat_state.dart';
import 'package:blue_mesh/chat_message.dart';
import 'package:blue_mesh/mesh_chat_tab.dart';
import 'package:blue_mesh/discovery_tab.dart';

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class FakeChatMessage extends Fake implements ChatMessage {}

void main() {
  late MockBluetoothRepository mockBtRepo;
  late MockLocalStorageRepository mockStorageRepo;
  late StreamController<dynamic> incomingMsgController;
  late StreamController<int> peerCountController;

  setUpAll(() {
    registerFallbackValue(FakeChatMessage());
  });

  setUp(() {
    mockBtRepo = MockBluetoothRepository();
    mockStorageRepo = MockLocalStorageRepository();
    incomingMsgController = StreamController<dynamic>.broadcast();
    peerCountController = StreamController<int>.broadcast();

    when(() => mockBtRepo.incomingMessages)
        .thenAnswer((_) => incomingMsgController.stream);
    when(() => mockBtRepo.activePeerCount)
        .thenAnswer((_) => peerCountController.stream);
    when(() => mockStorageRepo.getAllMessages()).thenReturn([]);
    when(() => mockStorageRepo.getUserName()).thenReturn('Node_Alpha');
    when(() => mockStorageRepo.getPendingQueue()).thenReturn([]);
    when(() => mockStorageRepo.saveMessage(any())).thenAnswer((_) async {});
    when(() => mockStorageRepo.queuePendingMessage(any()))
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await incomingMsgController.close();
    await peerCountController.close();
  });

  group('ChatBloc Unit Tests', () {
    test('initial state hydrates messages from Hive storage', () async {
      final bloc = ChatBloc(
        btRepository: mockBtRepo,
        storageRepository: mockStorageRepo,
      );
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.connectedPeerCount, 0);
      expect(bloc.state.isHost, isFalse);
      await bloc.close();
    });

    test('emits updated message list and saves to Hive when peer is connected',
            () async {
          when(() => mockBtRepo.broadcastPayload(any()))
              .thenAnswer((_) async => true);

          final bloc = ChatBloc(
            btRepository: mockBtRepo,
            storageRepository: mockStorageRepo,
          );

          final futureState = expectLater(
            bloc.stream,
            emits(
              isA<ChatState>()
                  .having((s) => s.messages.length, 'messages.length', 1)
                  .having((s) => s.messages.first.text, 'text', 'Hello Mesh')
                  .having(
                      (s) => s.messages.first.senderName, 'senderName', 'Node_Alpha'),
            ),
          );

          bloc.add(SendGroupMessageRequested('Hello Mesh'));
          await futureState;

          verify(() => mockStorageRepo.saveMessage(any())).called(1);
          verifyNever(() => mockStorageRepo.queuePendingMessage(any()));
          await bloc.close();
        });

    test('queues message in offline box when no peers connected', () async {
      when(() => mockBtRepo.broadcastPayload(any()))
          .thenAnswer((_) async => false);

      final bloc = ChatBloc(
        btRepository: mockBtRepo,
        storageRepository: mockStorageRepo,
      );

      final futureState = expectLater(
        bloc.stream,
        emits(
          isA<ChatState>().having((s) => s.messages.length, 'messages.length', 1),
        ),
      );

      bloc.add(SendGroupMessageRequested('Offline Ping'));
      await futureState;

      verify(() => mockStorageRepo.queuePendingMessage(any())).called(1);
      await bloc.close();
    });

    test('updates peer count when activePeerCount stream emits', () async {
      final bloc = ChatBloc(
        btRepository: mockBtRepo,
        storageRepository: mockStorageRepo,
      );

      final futureState = expectLater(
        bloc.stream,
        emits(
          isA<ChatState>().having((s) => s.connectedPeerCount, 'peerCount', 3),
        ),
      );

      peerCountController.add(3);
      await futureState;
      await bloc.close();
    });
  });

  group('Blue Mesh UI Widget Tests', () {
    testWidgets('MeshChatTab renders standby status and channel card',
            (WidgetTester tester) async {
          tester.view.physicalSize = const Size(412, 915);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            MaterialApp(
              home: BlocProvider<ChatBloc>(
                create: (_) => ChatBloc(
                  btRepository: mockBtRepo,
                  storageRepository: mockStorageRepo,
                ),
                child: const MeshChatTab(),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('STORE-AND-FORWARD STANDBY'), findsOneWidget);
          expect(find.text('Bluetooth Group Mesh'), findsOneWidget);
          expect(find.text('Broadcast SOS'), findsOneWidget);
          expect(find.text('Ping Mesh'), findsOneWidget);
        });

    testWidgets('DiscoveryTab renders Host Group and Join Group buttons',
            (WidgetTester tester) async {
          tester.view.physicalSize = const Size(412, 915);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            MaterialApp(
              home: BlocProvider<ChatBloc>(
                create: (_) => ChatBloc(
                  btRepository: mockBtRepo,
                  storageRepository: mockStorageRepo,
                ),
                child: const DiscoveryTab(),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('Host Group'), findsOneWidget);
          expect(find.text('Join Group'), findsOneWidget);
          expect(find.text('TRANSCEIVER STANDBY'), findsOneWidget);
        });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_bloc.dart';
import 'chat_state.dart';

class PeerInfoSheet extends StatelessWidget {
  const PeerInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connected Mesh Peers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.connectedPeerCount,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text('Device Endpoint #${index + 1}'),
                      subtitle: const Text('Status: Active Stream'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
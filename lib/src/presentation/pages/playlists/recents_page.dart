import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'package:meloplay/src/bloc/recents/recents_bloc.dart';
import 'package:meloplay/src/core/di/service_locator.dart';
import 'package:meloplay/src/core/theme/themes.dart';
import 'package:meloplay/src/data/repositories/player_repository.dart';
import 'package:meloplay/src/presentation/widgets/player_bottom_app_bar.dart';
import 'package:meloplay/src/presentation/widgets/song_list_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class RecentsPage extends StatefulWidget {
  const RecentsPage({super.key});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> {
  final player = sl<MusicPlayer>();
  List<SongModel> listRecent = [];

  @override
  void initState() {
    super.initState();
    // Dispatch the FetchRecents event
    context.read<RecentsBloc>().add(FetchRecents());
  }

  @override
  Widget build(BuildContext context) {
    listRecent.clear();
    return Scaffold(
      // current song, play/pause button, song progress bar, song queue button
      bottomNavigationBar: const PlayerBottomAppBar(),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Themes.getTheme().primaryColor,
        elevation: 0,
        title: const Text('Recents'),
        actions: [IconButton(onPressed: ()async{

          for( var song in listRecent){
            if (song.data!=null) {
                final file = File(song.data);
// kkk
                try {
                                // ask for permission to manage external storage if not granted
                                if (!await Permission
                                    .manageExternalStorage.isGranted) {
                                  final status = await Permission
                                      .manageExternalStorage
                                      .request();

                                  if (status.isGranted) {
                                    debugPrint('Permission granted');
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Permission denied',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                                await file.delete();
                                debugPrint('Deleted ${song.title}');
                              } catch (e) {
                                debugPrint(
                                    'Failed to delete ${song.title}');
                              }
// ll
            }
          }

        }, icon: Icon(Icons.delete_forever))],
      ),
      body: Ink(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: Themes.getTheme().linearGradient,
        ),
        child: StreamBuilder<SequenceState?>(
          stream: player.sequenceState,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              context.read<RecentsBloc>().add(FetchRecents());
            }

            return BlocBuilder<RecentsBloc, RecentsState>(
              buildWhen: (_, current) => current is RecentsLoaded,
              builder: (context, state) {
                if (state is RecentsLoaded) {
                  listRecent = state.songs.toList();
                  return _buildBody(state);
                } else {
                  return const SizedBox();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(RecentsLoaded state) {
    if (state.songs.isEmpty) {
      return const Center(
        child: Text('No songs found'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: state.songs.length,
      itemBuilder: (context, index) {
        return SongListTile(
          song: state.songs[index],
          songs: state.songs,
        );
      },
    );
  }
}

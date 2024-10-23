import 'package:amity_sdk/amity_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_sample_app/core/constant/global_constant.dart';
import 'package:flutter_social_sample_app/core/widget/dialog/error_dialog.dart';
import 'package:flutter_social_sample_app/core/widget/reaction_widget.dart';

class ReactionListMessageScreen extends StatefulWidget {
  const ReactionListMessageScreen({Key? key, required this.messageId})
      : super(key: key);
  final String messageId;
  @override
  State<ReactionListMessageScreen> createState() =>
      _ReactionListMessageScreenState();
}

class _ReactionListMessageScreenState extends State<ReactionListMessageScreen> {

  List<AmityReaction> amityReactions = <AmityReaction>[];
  late ReactionLiveCollection reactionLiveCollection;

  final scrollcontroller = ScrollController();
  bool loading = false;

  @override
  void initState() {
    reactionLiveCollection = AmityChatClient.newMessageRepository()
        .getReaction(messageId: widget.messageId)
        .getLiveCollection();

    reactionLiveCollection.getStreamController().stream.listen((event) {
      if (mounted) {
        setState(() {
          amityReactions = event;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      reactionLiveCollection.loadNext();
    });

    scrollcontroller.addListener(pagination);

    super.initState();
  }

  void pagination() {
    if ((scrollcontroller.position.pixels ==
            scrollcontroller.position.maxScrollExtent) &&
        reactionLiveCollection.hasNextPage()) {
      setState(() {
        reactionLiveCollection.loadNext();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Message Reactions - ${widget.messageId}')),
      body: Column(
        children: [
          Expanded(
            child: amityReactions.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: () async {
                      reactionLiveCollection.reset();
                      reactionLiveCollection.loadNext();
                    },
                    child: ListView.builder(
                      controller: scrollcontroller,
                      itemCount: amityReactions.length,
                      itemBuilder: (context, index) {
                        final amityReaction = amityReactions[index];
                        return Container(
                          margin: const EdgeInsets.only(
                              left: 12, right: 12, top: 12),
                          child: ReactionWidget(
                            reaction: amityReaction,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    child: reactionLiveCollection.isFetching
                        ? const CircularProgressIndicator()
                        : const Text('No Post'),
                  ),
          ),
          if (reactionLiveCollection.isFetching && amityReactions.isNotEmpty)
            Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
        ],
      ),
    );
  }
}